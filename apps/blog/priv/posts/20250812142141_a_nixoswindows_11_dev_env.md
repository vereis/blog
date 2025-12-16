---
title: A NixOS/Windows 11 Dev Env
slug: a-nixoswindows-11-dev-env
is_draft: false
reading_time_minutes:
published_at: 2025-08-12 14:21:41.523524Z
tags:
  - nixos
  - windows
---

I live in the terminal.

Like, **everything** I do is CLI-driven. My entire development workflow happens in my terminal emulator of choice, whether I'm on NixOS bare metal or Windows 11.

I also switch operating systems very often; and I run multiple machines each potentially running different things.

As a result, I need a development environment that is:
- **Reproducible**: I want to be able to set up my environment on any machine with minimal effort.
- **Works the same everywhere**: I want my tools and configurations to behave consistently across different systems.
- **Cross-platform**: I want to use the best tools from both worlds - Unix/Linux and Windows.

Currently, I'm running Windows 11 on my workstation because it's summer and my friends want to play games, but I also need to work.

I decided to write up my process for setting up a NixOS/Windows 11 development environment that meets these requirements.

> If you're interested in my broader setup, check out my [setup overview](/posts/uses) or my thoughts on [NixOS in general](/posts/nixos_kool_aid).

## Why Windows 11 LTSC?

I run Windows 11 LTSC (Long-Term Servicing Channel) specifically.

If you're not familiar, here's a quick overview of the different Windows 11 editions and their update policies:

| Edition | Updates | Bloatware | Support | Use Case |
|---------|---------|-----------|---------|----------|
| **Windows 11 Home/Pro** | Feature updates twice yearly + monthly security | Xbox, Weather, News, Store, Cortana, etc. | Standard lifecycle | General users |
| **Windows 11 Enterprise** | Same as Pro + advanced management | Same as Pro | Volume licensing only | Large organizations |
| **Windows 11 LTSC** | Security updates only (6 months) | None - minimal installation | 5-10 years | Specialized systems |

The core reason I'm using LTSC is its minimalism and stability:

- No feature updates (and thus no forced reboots).
- No unnecessary bloatware or background services (Xbox, Weather, News, etc.).
- Supposedly more efficient, though my hardware is powerful enough that I can't validate this.

There is a problem though: Getting a legitimate LTSC license is nearly impossible for individuals.

> Microsoft only sells it to enterprises through volume licensing agreements.

## The License Situation

Getting a legitimate Windows 11 LTSC license as an individual is challenging but not impossible.

Microsoft restricts LTSC to volume licensing customers - typically large organizations. Individual consumers cannot purchase LTSC directly from Microsoft.

**Legitimate Options for Individuals:**

**Microsoft Authorized Resellers**: Some authorized Microsoft partners offer Windows 11 Enterprise LTSC licenses to individuals, though most require volume licensing agreements.

**Evaluation Version**: Microsoft provides a 90-day evaluation version of Windows 11 IoT Enterprise LTSC for testing purposes. I obtained my evaluation copy through [massgrave.dev](https://massgrave.dev), which also provides tools for extending the evaluation period.

**Volume Licensing**: If you have a business or can justify enterprise use, you can work with Microsoft authorized resellers to obtain proper licensing.

**Third-Party Vendors**: Some legitimate vendors sell Windows 11 Enterprise LTSC + Software Assurance, though availability and legitimacy vary.

The reality is Microsoft intentionally restricts LTSC to enterprise customers for mission-critical environments like medical devices, ATMs, and industrial systems.

> This guide should work on any version of Windows 11, including Home, Pro, Enterprise, or LTSC.

> I spent more time researching legitimate ways to buy LTSC than actually setting up the development environment. The options exist but require more effort than regular Windows licenses.

## The Simple Setup

I've been using tools like Cygwin for a long time, but since WSL and WSL2 were released, I practically only use WSL2 for all tasks in Windows.

As I'm using NixOS as my Linux distribution of choice, I've also been using that within WSL2 to get the best of both worlds.

My terminal emulator of choice is Wezterm, which runs natively across NixOS, Windows, and even macOS.

This setup allows me to have a practically identical setup across all my machines, regardless of the underlying operating system.

## Windows Initial Setup

After dealing with activation (your choice of method), I install the essentials:

```powershell
Set-ExecutionPolicy Unrestricted
winget install SlackTechnologies.Slack
winget install Discord.Discord
winget install Valve.Steam
winget install Mojang.MinecraftLauncher
winget install wezterm
winget install altdrag
```

Windows 11 LTSC doesn't come with the Microsoft Store, so I use `winget` for package management.

```powershell
Add-AppxPackage "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.8.6" -OutFile "microsoft.ui.xaml.2.8.6.zip"
Expand-Archive .\microsoft.ui.xaml.2.8.6.zip
Add-AppPackage .\microsoft.ui.xaml.2.8.6\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.8.appx
```

This is just the initial Windows setup though. Once NixOS-WSL is running, I manage Windows packages from my Linux terminal.

## NixOS-WSL Installation

Install WSL2 without a default distribution:

```powershell
wsl --install --no-distribution
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Download the latest NixOS-WSL release from the [releases page](https://github.com/nix-community/NixOS-WSL/releases), then:

```powershell
wsl --import NixOS $env:USERPROFILE\NixOS\ nixos-wsl.tar.gz --version 2
```

Launch your real development environment:

```powershell
wsl -d NixOS
```

This drops you into a shell running NixOS, where I can simply run:

```bash
nix-shell -p git vim
git clone https://github.com/vereis/nix-config
cd nix-config
sudo nixos-rebuild switch --flake .#madoka
wsl.exe --shutdown
```

Then the next time I run `wsl` (or launch Wezterm), everything works exactly as expected.

## Cross-Platform Command Integration

From my NixOS terminal, I can seamlessly use Windows tools:

```bash
# SSH into other machines using Windows Tailscale
tailscale.exe ssh my-server

# Install Windows packages without leaving Linux shell
winget.exe install Microsoft.VisualStudioCode

# Check Windows network status
ipconfig.exe

# Use Windows clipboard
clip.exe < some_file.txt
```

This integration is what makes the setup powerful.

Unix development environment + Windows-specific tools when needed.

I even get sane copy and pasting working because WSL2 automatically syncs clipboards as long as `xclip` is installed on the NixOS side, including inside `vim` or `zellij`.

## The Nix Configuration

My [nix-config](https://github.com/vereis/nix-config) uses flakes for reproducible environments:

- `machines/` - Platform-specific configs (including WSL)
- `modules/` - Reusable development tool configurations
- `overlays/` - Custom package versions and modifications

Setting it up:

```bash
nix-shell -p git vim
git clone https://github.com/vereis/nix-config
cd nix-config
sudo nixos-rebuild switch --flake .#madoka
```

Everything gets installed declaratively.

Language servers, shell utilities, Neovim with AI integration - all defined in Nix configuration files.

## Working on Something Cool

I'm building a NixOS module that lets me install winget packages from my Nix config:

```nix
# In my NixOS configuration
modules.wsl.wingetPackages = [
  "SlackTechnologies.Slack"
  "Discord.Discord"
  "wezterm"
];
```

Since WSL can execute Windows binaries directly, the module calls `winget.exe install` for each package during system activation.

I'm also working on automated dotfile symlinks between Linux and Windows:

```nix
windows.symlinkDotfiles = {
  wezterm = {
    source = "/home/vereis/.config/wezterm";
    target = "/mnt/c/Users/vereis/.config/wezterm";
  };
  ssh = {
    source = "/home/vereis/.ssh";
    target = "/mnt/c/Users/vereis/.ssh";
  };
};
```

> The goal is never manually managing anything on Windows. Pure declarative configuration for everything.

## File System Integration

Windows drives mount automatically in `/mnt/c/`, `/mnt/d/`, etc.

Dotfiles can be shared between environments:

```bash
# Create shared config directories
mkdir -p /mnt/c/Users/vereis/.config/wezterm

# Symlink from NixOS to Windows location
ln -sf /mnt/c/Users/vereis/.config/wezterm ~/.config/wezterm
```

Both Windows Wezterm and NixOS Wezterm use the same configuration.

You can also access NixOS files from Windows via `\\wsl.localhost\NixOS\home\username\`.

## Network Integration Magic

One piece that's different between my NixOS and Windows environments is networking.

I use Tailscale on all my machines to let me easily access them over a secure mesh VPN, but for WSL2 hosts I'll actually omit setting up Tailscale inside the WSL2 instance and instead run it on the Windows host.

This is because WSL2 distros share the Windows host's network stack, so Tailscale running on Windows automatically routes traffic to WSL2 and I'm none the wiser.

> To be honest, I need to remember to run `tailscale.exe` instead of `tailscale` but that could be fixed with a simple alias if I were bothered.

```bash
# SSH into my NixOS laptop from Windows desktop
tailscale.exe ssh nixos-laptop

# Access services on other Tailscale nodes
curl http://sayaka:8080/api/status
```

## GUI Applications

Because I don't use many GUI applications, most of my setup works out of the box after following the above steps.

I actually find Microsoft Edge to be a really decent browser, and it runs on Chromium, so honestly I don't feel like I miss Firefox or anything else outside of philosophical reasons.

As long as I can declaratively manage my Windows applications, I'm happy.

## Conclusion

This setup gives me the best of both worlds: Windows for gaming and native applications, NixOS for development work.

WSL2 makes the integration seamless, and having identical terminal environments across different machines is genuinely useful.

The declarative nature of Nix means I can reproduce this setup anywhere with minimal effort.

It's not perfect, but it works well for my workflow.
