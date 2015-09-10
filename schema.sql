CREATE EXTENSION ltree;

CREATE TABLE tree (
  id SERIAL NOT NULL PRIMARY KEY,
  parent_id integer,
  path ltree,
  name character varying(256) NOT NULL,

  created_on timestamp with time zone DEFAULT now() NOT NULL,
  updated_on timestamp with time zone DEFAULT now() NOT NULL
);



-----------------------------------------------
-- http://www.postgresonline.com/journal/archives/173-Using-LTree-to-Represent-and-Query-tree-and-Tree-Structures.html
CREATE UNIQUE INDEX idx_tree_path_btree_idx ON tree USING btree(path);
CREATE        INDEX idx_tree_path_gist_idx  ON tree USING gist(path);

CREATE OR REPLACE FUNCTION get_calculated_tree_path(param_t_id integer)
  RETURNS ltree AS
$$
  SELECT CASE 
    WHEN t.parent_id IS NULL THEN t.id::text::ltree 
    ELSE get_calculated_tree_path(t.parent_id) || t.id::text END
  FROM tree AS t
  WHERE t.id = $1;
$$
  LANGUAGE sql;

CREATE OR REPLACE FUNCTION trigger_update_tree_path() RETURNS trigger AS
$$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF (COALESCE(OLD.parent_id,0) != COALESCE(NEW.parent_id,0) OR NEW.id != OLD.id) THEN
      -- update all nodes that are children of this one including this one
      UPDATE tree SET path = get_calculated_tree_path(id) 
        WHERE OLD.path @> tree.path;
    END IF;
  ELSIF TG_OP = 'INSERT' THEN
    UPDATE tree SET path = get_calculated_tree_path(NEW.id) WHERE tree.id = NEW.id;
  END IF;
  
  RETURN NEW;
END
$$
LANGUAGE 'plpgsql' VOLATILE;

CREATE TRIGGER trigger01_update_tree_path AFTER INSERT OR UPDATE OF id, parent_id
  ON tree FOR EACH ROW
  EXECUTE PROCEDURE trigger_update_tree_path();
-----------------------------------------------


-- Starter data loaded from an foreign source:
-- psql -d nemo -t -A -F"," -c "select id, parent_id, name from targets where path ~ '*.17.*'" > in.csv
-- tree=# \copy tree(id, parent_id, name) from 'in.csv' delimiter ',' CSV;
-- COPY 24


