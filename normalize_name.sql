CREATE OR REPLACE FUNCTION ebg_qa.normalize_name(name text)
RETURNS text AS $$
BEGIN
    name := initcap(name);
    name := replace(name, '.', ''); -- Remove periods
    name := replace(name, ',', ''); -- Remove commas
    RETURN array_to_string(
        ARRAY(SELECT DISTINCT unnest(string_to_array(name, ' ')) ORDER BY 1),
        ' '
    );
END;

$$ LANGUAGE plpgsql IMMUTABLE;
