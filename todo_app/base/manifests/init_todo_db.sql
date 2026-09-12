CREATE TABLE IF NOT EXISTS todos (
  id serial PRIMARY KEY,
  title text NOT NULL,
  done boolean NOT NULL DEFAULT FALSE
);

ALTER TABLE todos ADD COLUMN IF NOT EXISTS done boolean NOT NULL DEFAULT FALSE;

-- Can be used to add default entries to database
-- INSERT INTO todos (title) VALUES ('Learn Kubernetes basics');
-- INSERT INTO todos (title) VALUES ('Deploy application to cluster');
-- INSERT INTO todos (title) VALUES ('Configure persistent volumes');