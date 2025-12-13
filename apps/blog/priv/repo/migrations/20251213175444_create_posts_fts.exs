# excellent_migrations:safety-assured-for-this-file raw_sql_executed
defmodule Blog.Repo.Migrations.CreatePostsFts do
  use Ecto.Migration

  def change do
    execute(
      """
      CREATE VIRTUAL TABLE posts_fts USING fts5(
        post_id,
        title,
        raw_body,
        excerpt,
        tags,
        tokenize='porter unicode61'
      );
      """,
      """
      DROP TABLE posts_fts;
      """
    )

    execute(
      """
      CREATE TRIGGER insert_posts_fts
        AFTER INSERT ON posts
      FOR EACH ROW
      BEGIN
        INSERT INTO posts_fts (
          post_id,
          title,
          raw_body,
          excerpt
        )
        VALUES (
          new.id,
          new.title,
          new.raw_body,
          new.excerpt
        );
      END;
      """,
      """
      DROP TRIGGER insert_posts_fts;
      """
    )

    execute(
      """
      CREATE TRIGGER update_posts_fts
        AFTER UPDATE ON posts
      FOR EACH ROW
      BEGIN
        UPDATE posts_fts
        SET
          title = new.title,
          raw_body = new.raw_body,
          excerpt = new.excerpt
        WHERE post_id = new.id;
      END;
      """,
      """
      DROP TRIGGER update_posts_fts;
      """
    )

    execute(
      """
      CREATE TRIGGER delete_posts_fts
        AFTER DELETE ON posts
      FOR EACH ROW
      BEGIN
        DELETE FROM posts_fts WHERE post_id = old.id;
      END;
      """,
      """
      DROP TRIGGER delete_posts_fts;
      """
    )

    execute(
      """
      CREATE TRIGGER insert_tags_fts
        AFTER INSERT ON posts_tags
      FOR EACH ROW
      BEGIN
        UPDATE posts_fts
        SET tags = (
          SELECT GROUP_CONCAT(tags.label, ', ')
          FROM tags
          JOIN posts_tags ON tags.id = posts_tags.tag_id
          WHERE posts_tags.post_id = NEW.post_id
        )
        WHERE post_id = NEW.post_id;
      END;
      """,
      """
      DROP TRIGGER insert_tags_fts;
      """
    )

    execute(
      """
      CREATE TRIGGER update_tags_fts
        AFTER UPDATE ON posts_tags
      FOR EACH ROW
      BEGIN
        UPDATE posts_fts
        SET tags = (
          SELECT GROUP_CONCAT(tags.label, ', ')
          FROM tags
          JOIN posts_tags ON tags.id = posts_tags.tag_id
          WHERE posts_tags.post_id = NEW.post_id
        )
        WHERE post_id = NEW.post_id;
      END;
      """,
      """
      DROP TRIGGER update_tags_fts;
      """
    )

    execute(
      """
      CREATE TRIGGER delete_tags_fts
        AFTER DELETE ON posts_tags
      FOR EACH ROW
      BEGIN
        UPDATE posts_fts
        SET tags = (
          SELECT GROUP_CONCAT(tags.label, ', ')
          FROM tags
          JOIN posts_tags ON tags.id = posts_tags.tag_id
          WHERE posts_tags.post_id = OLD.post_id
        )
        WHERE post_id = OLD.post_id;
      END;
      """,
      """
      DROP TRIGGER delete_tags_fts;
      """
    )
  end
end
