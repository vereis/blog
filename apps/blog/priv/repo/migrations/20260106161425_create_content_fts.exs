# excellent_migrations:safety-assured-for-this-file raw_sql_executed
defmodule Blog.Repo.Migrations.CreateContentFts do
  use Ecto.Migration

  def change do
    execute(
      """
      CREATE VIRTUAL TABLE content_fts USING fts5(
        slug,
        type,
        title,
        raw_body,
        excerpt,
        description,
        tokenize='porter unicode61'
      );
      """,
      """
      DROP TABLE content_fts;
      """
    )

    execute(
      """
      CREATE TRIGGER insert_content_fts
        AFTER INSERT ON content
      FOR EACH ROW
      WHEN new.deleted_at IS NULL
      BEGIN
        INSERT INTO content_fts (
          slug,
          type,
          title,
          raw_body,
          excerpt,
          description
        )
        VALUES (
          new.slug,
          new.type,
          new.title,
          new.raw_body,
          new.excerpt,
          new.description
        );
      END;
      """,
      """
      DROP TRIGGER insert_content_fts;
      """
    )

    execute(
      """
      CREATE TRIGGER update_content_fts
        AFTER UPDATE ON content
      FOR EACH ROW
      BEGIN
        DELETE FROM content_fts WHERE slug = old.slug;
        INSERT INTO content_fts (
          slug,
          type,
          title,
          raw_body,
          excerpt,
          description
        )
        SELECT
          new.slug,
          new.type,
          new.title,
          new.raw_body,
          new.excerpt,
          new.description
        WHERE new.deleted_at IS NULL;
      END;
      """,
      """
      DROP TRIGGER update_content_fts;
      """
    )

    execute(
      """
      CREATE TRIGGER delete_content_fts
        AFTER DELETE ON content
      FOR EACH ROW
      BEGIN
        DELETE FROM content_fts WHERE slug = old.slug;
      END;
      """,
      """
      DROP TRIGGER delete_content_fts;
      """
    )
  end
end
