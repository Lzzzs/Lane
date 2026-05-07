import Foundation
import GRDB

public enum Migrations {
    public static func register() -> DatabaseMigrator {
        var m = DatabaseMigrator()

        m.registerMigration("v1_initial_schema") { db in
            try db.execute(sql: """
                CREATE TABLE group_ (
                    id          TEXT PRIMARY KEY,
                    name        TEXT NOT NULL,
                    color       TEXT NOT NULL,
                    icon        TEXT NOT NULL,
                    sort_order  INTEGER NOT NULL,
                    created_at  DATETIME NOT NULL
                );

                CREATE TABLE stage_template (
                    id          TEXT PRIMARY KEY,
                    name        TEXT NOT NULL,
                    is_default  BOOLEAN NOT NULL DEFAULT 0,
                    created_at  DATETIME NOT NULL
                );

                CREATE TABLE stage_template_item (
                    id          TEXT PRIMARY KEY,
                    template_id TEXT NOT NULL REFERENCES stage_template(id) ON DELETE CASCADE,
                    name        TEXT NOT NULL,
                    sort_order  INTEGER NOT NULL
                );

                CREATE TABLE requirement (
                    id          TEXT PRIMARY KEY,
                    group_id    TEXT NOT NULL REFERENCES group_(id) ON DELETE RESTRICT,
                    title       TEXT NOT NULL,
                    description TEXT NOT NULL DEFAULT '',
                    template_id TEXT REFERENCES stage_template(id) ON DELETE RESTRICT,
                    status      TEXT NOT NULL DEFAULT 'active',
                    sort_order  INTEGER NOT NULL,
                    created_at  DATETIME NOT NULL,
                    updated_at  DATETIME NOT NULL,
                    deleted_at  DATETIME
                );

                CREATE TABLE stage_instance (
                    id              TEXT PRIMARY KEY,
                    requirement_id  TEXT NOT NULL REFERENCES requirement(id) ON DELETE CASCADE,
                    name            TEXT NOT NULL,
                    sort_order      INTEGER NOT NULL,
                    start_date      DATE,
                    end_date        DATE,
                    status          TEXT NOT NULL DEFAULT 'pending'
                );

                CREATE TABLE todo (
                    id                  TEXT PRIMARY KEY,
                    stage_instance_id   TEXT NOT NULL REFERENCES stage_instance(id) ON DELETE CASCADE,
                    title               TEXT NOT NULL,
                    done                BOOLEAN NOT NULL DEFAULT 0,
                    done_at             DATETIME,
                    sort_order          INTEGER NOT NULL,
                    created_at          DATETIME NOT NULL
                );

                CREATE TABLE external_link (
                    id              TEXT PRIMARY KEY,
                    requirement_id  TEXT NOT NULL REFERENCES requirement(id) ON DELETE CASCADE,
                    label           TEXT NOT NULL,
                    url             TEXT NOT NULL,
                    sort_order      INTEGER NOT NULL
                );

                CREATE TABLE today_pin (
                    requirement_id  TEXT NOT NULL REFERENCES requirement(id) ON DELETE CASCADE,
                    pinned_date     DATE NOT NULL,
                    PRIMARY KEY (requirement_id, pinned_date)
                );

                CREATE TABLE setting (
                    key   TEXT PRIMARY KEY,
                    value TEXT NOT NULL
                );

                CREATE INDEX idx_requirement_group ON requirement(group_id);
                CREATE INDEX idx_requirement_status_deleted ON requirement(status, deleted_at);
                CREATE INDEX idx_stage_requirement ON stage_instance(requirement_id);
                CREATE INDEX idx_stage_dates ON stage_instance(start_date, end_date);
                CREATE INDEX idx_todo_stage ON todo(stage_instance_id);
                CREATE INDEX idx_todo_done_at ON todo(done_at);
            """)
        }

        return m
    }
}
