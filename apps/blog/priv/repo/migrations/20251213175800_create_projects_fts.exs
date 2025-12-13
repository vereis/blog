# excellent_migrations:safety-assured-for-this-file raw_sql_executed
defmodule Blog.Repo.Migrations.CreateProjectsFts do
  use Ecto.Migration

  def change do
    execute(
      """
      CREATE VIRTUAL TABLE projects_fts USING fts5(
        project_id,
        name,
        description,
        tags,
        tokenize='porter unicode61'
      );
      """,
      """
      DROP TABLE projects_fts;
      """
    )

    execute(
      """
      CREATE TRIGGER insert_projects_fts
        AFTER INSERT ON projects
      FOR EACH ROW
      BEGIN
        INSERT INTO projects_fts (
          project_id,
          name,
          description
        )
        VALUES (
          new.id,
          new.name,
          new.description
        );
      END;
      """,
      """
      DROP TRIGGER insert_projects_fts;
      """
    )

    execute(
      """
      CREATE TRIGGER update_projects_fts
        AFTER UPDATE ON projects
      FOR EACH ROW
      BEGIN
        UPDATE projects_fts
        SET
          name = new.name,
          description = new.description
        WHERE project_id = new.id;
      END;
      """,
      """
      DROP TRIGGER update_projects_fts;
      """
    )

    execute(
      """
      CREATE TRIGGER delete_projects_fts
        AFTER DELETE ON projects
      FOR EACH ROW
      BEGIN
        DELETE FROM projects_fts WHERE project_id = old.id;
      END;
      """,
      """
      DROP TRIGGER delete_projects_fts;
      """
    )

    execute(
      """
      CREATE TRIGGER insert_project_tags_fts
        AFTER INSERT ON projects_tags
      FOR EACH ROW
      BEGIN
        UPDATE projects_fts
        SET tags = (
          SELECT GROUP_CONCAT(tags.label, ', ')
          FROM tags
          JOIN projects_tags ON tags.id = projects_tags.tag_id
          WHERE projects_tags.project_id = NEW.project_id
        )
        WHERE project_id = NEW.project_id;
      END;
      """,
      """
      DROP TRIGGER insert_project_tags_fts;
      """
    )

    execute(
      """
      CREATE TRIGGER update_project_tags_fts
        AFTER UPDATE ON projects_tags
      FOR EACH ROW
      BEGIN
        UPDATE projects_fts
        SET tags = (
          SELECT GROUP_CONCAT(tags.label, ', ')
          FROM tags
          JOIN projects_tags ON tags.id = projects_tags.tag_id
          WHERE projects_tags.project_id = NEW.project_id
        )
        WHERE project_id = NEW.project_id;
      END;
      """,
      """
      DROP TRIGGER update_project_tags_fts;
      """
    )

    execute(
      """
      CREATE TRIGGER delete_project_tags_fts
        AFTER DELETE ON projects_tags
      FOR EACH ROW
      BEGIN
        UPDATE projects_fts
        SET tags = (
          SELECT GROUP_CONCAT(tags.label, ', ')
          FROM tags
          JOIN projects_tags ON tags.id = projects_tags.tag_id
          WHERE projects_tags.project_id = OLD.project_id
        )
        WHERE project_id = OLD.project_id;
      END;
      """,
      """
      DROP TRIGGER delete_project_tags_fts;
      """
    )
  end
end
