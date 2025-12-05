defmodule Blog.Assets.Types.Image do
  @moduledoc "Handles image asset processing for changing image type `Blog.Assets.Asset`s"

  use Blog.Assets.Types

  import Bitwise

  alias Vix.Vips.Image, as: VixImage
  alias Vix.Vips.Operation

  # NOTE: LQIP quantization levels and ranges (based on https://leanrada.com/notes/css-only-lqip/)
  @l_levels 4
  @ab_levels 8
  @l_min 0.2
  @l_max 0.8
  @a_min -0.35
  @a_max 0.35
  @b_min -0.35
  @b_max 0.35

  @impl Blog.Assets.Types
  def handle_type(changeset) when not valid?(changeset) do
    changeset
  end

  def handle_type(changeset) when not changes?(changeset, :path) do
    changeset
  end

  def handle_type(changeset) do
    path = get_change(changeset, :path)

    case VixImage.new_from_file(path) do
      {:ok, image} ->
        name =
          path
          |> Path.basename()
          |> Path.rootname()
          |> Kernel.<>(".webp")

        changeset
        |> optimize_image(image, name)
        |> generate_lqip(image)
        |> validate_required([:data, :width, :height, :content_type, :lqip_hash])

      {:error, reason} ->
        add_error(changeset, :path, "Failed to load image: #{inspect(reason)}")
    end
  end

  defp optimize_image(changeset, image, name) do
    case VixImage.write_to_buffer(image, ".webp", Q: 80, strip: true) do
      {:ok, optimized_data} ->
        changeset
        |> put_change(:data, optimized_data)
        |> put_change(:width, VixImage.width(image))
        |> put_change(:height, VixImage.height(image))
        |> put_change(:content_type, "image/webp")
        |> put_change(:type, :image)
        |> put_change(:name, name)

      {:error, reason} ->
        add_error(changeset, :path, "Failed to optimize image: #{inspect(reason)}")
    end
  end

  # Generates a 20-bit LQIP (Low Quality Image Placeholder) hash from an image.
  # Based on https://leanrada.com/notes/css-only-lqip/
  defp generate_lqip(changeset, image) do
    with {:ok, thumbnail} <- Operation.thumbnail_image(image, 3, height: 2),
         {:ok, sharpened} <- Operation.sharpen(thumbnail, sigma: 1.0),
         {:ok, binary} <- VixImage.write_to_binary(sharpened) do
      oklab_pixels =
        binary
        |> :binary.bin_to_list()
        |> Enum.chunk_every(3)
        |> Enum.map(fn [r, g, b] -> rgb_to_oklab(r, g, b) end)

      {base_l, base_a, base_b} = get_average_oklab(oklab_pixels)
      {ll, aaa, bbb} = find_best_oklab_bits(base_l, base_a, base_b)
      decoded_base_l = ll / 3.0 * 0.6 + 0.2

      # NOTE: Extract 6 RELATIVE brightness components (relative to base luminance!)
      components =
        Enum.map(oklab_pixels, fn {cell_l, _a, _b} ->
          # Relative brightness: 0.5 + difference from base
          relative = 0.5 + (cell_l - decoded_base_l)
          clamped = max(0.0, min(1.0, relative))
          # Quantize to 2 bits (0-3)
          round(clamped * 3)
        end)

      put_change(changeset, :lqip_hash, encode_lqip_signed(ll, aaa, bbb, components))
    else
      {:error, reason} ->
        add_error(changeset, :path, "Failed to generate LQIP hash: #{inspect(reason)}")
    end
  end

  # NOTE: Returns {L, a, b} where L is 0-1, a and b are roughly -0.4 to 0.4
  defp rgb_to_oklab(r, g, b) do
    # Normalize to 0-1
    r_lin = gamma_to_linear(r / 255.0)
    g_lin = gamma_to_linear(g / 255.0)
    b_lin = gamma_to_linear(b / 255.0)

    # RGB to LMS (using Oklab matrix)
    l = 0.4122214708 * r_lin + 0.5363325363 * g_lin + 0.0514459929 * b_lin
    m = 0.2119034982 * r_lin + 0.6806995451 * g_lin + 0.1073969566 * b_lin
    s = 0.0883024619 * r_lin + 0.2817188376 * g_lin + 0.6299787005 * b_lin

    # LMS to Oklab (add epsilon to prevent issues with negative/zero values)
    l_ = :math.pow(max(l, 1.0e-10), 1 / 3)
    m_ = :math.pow(max(m, 1.0e-10), 1 / 3)
    s_ = :math.pow(max(s, 1.0e-10), 1 / 3)

    ok_l = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
    ok_a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
    ok_b = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_

    {ok_l, ok_a, ok_b}
  end

  defp gamma_to_linear(v) when v <= 0.04045 do
    v / 12.92
  end

  defp gamma_to_linear(v) do
    :math.pow((v + 0.055) / 1.055, 2.4)
  end

  # NOTE: Returns a sensible default (mid-gray) for empty lists
  defp get_average_oklab([]) do
    {0.5, 0.0, 0.0}
  end

  defp get_average_oklab(oklab_pixels) do
    {l_sum, a_sum, b_sum} =
      Enum.reduce(oklab_pixels, {0.0, 0.0, 0.0}, fn {l, a, b}, {l_acc, a_acc, b_acc} ->
        {l_acc + l, a_acc + a, b_acc + b}
      end)

    count = length(oklab_pixels)
    {l_sum / count, a_sum / count, b_sum / count}
  end

  defp find_best_oklab_bits(target_l, target_a, target_b) do
    target_chroma = :math.sqrt(target_a * target_a + target_b * target_b)

    # Try all 128 combinations and find the best
    # Scale chroma components for better comparison
    # Calculate difference
    for_result =
      for ll <- 0..3, aaa <- 0..7, bbb <- 0..7 do
        {l, a, b} = bits_to_oklab(ll, aaa, bbb)
        chroma = :math.sqrt(a * a + b * b)
        scaled_a = scale_for_diff(a, chroma)
        scaled_b = scale_for_diff(b, chroma)
        scaled_target_a = scale_for_diff(target_a, target_chroma)
        scaled_target_b = scale_for_diff(target_b, target_chroma)

        diff =
          :math.sqrt(
            :math.pow(l - target_l, 2) +
              :math.pow(scaled_a - scaled_target_a, 2) +
              :math.pow(scaled_b - scaled_target_b, 2)
          )

        {diff, ll, aaa, bbb}
      end

    best =
      Enum.min_by(for_result, fn {diff, _, _, _} -> diff end)

    {_, ll, aaa, bbb} = best
    {ll, aaa, bbb}
  end

  # NOTE: Scales chroma components for perceptual distance calculation
  #       Uses power-law scaling to better match human color perception
  #       Based on the reference implementation at https://leanrada.com/notes/css-only-lqip/
  defp scale_for_diff(x, chroma) do
    x / (1.0e-6 + :math.pow(chroma, 0.5))
  end

  defp bits_to_oklab(ll, aaa, bbb) do
    l = ll / (@l_levels - 1) * (@l_max - @l_min) + @l_min
    a = aaa / @ab_levels * (@a_max - @a_min) + @a_min
    b = (bbb + 1) / @ab_levels * (@b_max - @b_min) + @b_min
    {l, a, b}
  end

  defp encode_lqip_signed(ll, aaa, bbb, [ca, cb, cc, cd, ce, cf]) do
    # NOTE: Upper 12 bits: 6 components (2 bits each, in order ca through cf)
    #       Lower 8 bits: base color (ll in bits 6-7, aaa in bits 3-5, bbb in bits 0-2)
    unsigned =
      (ca &&& 0b11) <<< 18 |||
        (cb &&& 0b11) <<< 16 |||
        (cc &&& 0b11) <<< 14 |||
        (cd &&& 0b11) <<< 12 |||
        (ce &&& 0b11) <<< 10 |||
        (cf &&& 0b11) <<< 8 |||
        (ll &&& 0b11) <<< 6 |||
        (aaa &&& 0b111) <<< 3 |||
        (bbb &&& 0b111)

    # NOTE: Apply offset to make it signed (matches referenced JS implementation)
    #       This maps [0, 2^20) to [-2^19, 2^19)
    signed = unsigned - Integer.pow(2, 19)

    if signed < -524_288 or signed > 524_287 do
      raise "LQIP hash out of valid 20-bit signed range: #{signed}"
    end

    signed
  end
end
