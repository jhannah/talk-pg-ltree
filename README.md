# talk-pg-ltree

Hierarchical data using [PostgreSQL ltree extension](http://www.postgresql.org/docs/9.4/static/ltree.html)...
SoEasy!

## From scratch

    $ psql -c "create database tree"
    $ psql tree < schema.sql
    $ psql tree
    tree=# \copy tree(id, parent_id, name) from 'in.csv' delimiter ',' CSV;

That's it. You can now `select *` to see all the columns. Notice that
the `path` column has been automagically propogated with the path
to each row in integers, via the triggers and stored procedure in the 
`schema.sql` file.

Then witness the materialized path magic like so:

    SELECT t.id, t.path, t.name, array_to_string(array_agg(a.name ORDER BY a.path), ' > ') AS fullname
    FROM tree AS t INNER JOIN tree AS a
      ON (a.path @> t.path)
    GROUP BY t.id, t.path, t.name
    ORDER BY fullname;

You can now use all the [ltree operators and functions](http://www.postgresql.org/docs/9.4/static/ltree.html) 
on the path column. For example, maybe you only want to see the
tree with "Other Mobile Device" in the middle:

    SELECT t.id, t.path, t.name, array_to_string(array_agg(a.name ORDER BY a.path), ' > ') AS fullname
    FROM tree AS t INNER JOIN tree AS a
      ON (a.path @> t.path)
    WHERE t.path ~ '*.75141.*'
    GROUP BY t.id, t.path, t.name
    ORDER BY fullname;

Or maybe you want the tree terminating in "Linux Laptop/Desktop":

Hmmm... not working yet...: wassup with that?

    SELECT t.id, t.path, t.name, array_to_string(array_agg(a.name ORDER BY a.path), ' > ') AS fullname
    FROM tree AS t INNER JOIN tree AS a
      ON (a.path @> t.path)
    WHERE t.path @> '300938'
    GROUP BY t.id, t.path, t.name
    ORDER BY fullname;



