
CREATE OR REPLACE FUNCTION normalize_address(p_address text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
PARALLEL SAFE
STRICT
AS
$$

/* ####################################################################################################################################################
   Function Name : normalize_address

   Created By     : Pablo Hernandez
   Version        : Release 1.0.0
   Created On     : 2026-02-13

   Description:
     - This function helps create a normalize address version focusing on the street elements only for comparison purposes

-------------------------------------------------------------------------------------------------------------------------------------------------------------
                                										MODIFICATION LOG
-------------------------------------------------------------------------------------------------------------------------------------------------------------
   VERSION          | DATE       | AUTHOR                | DESCRIPTION
   ----------------------------------------------------------------------------------------------------------------------------------------------------------
   Beta 1.0         | 2026-02-13 | Pablo Hernandez       | Creation
   ----------------------------------------------------------------------------------------------------------------------------------------------------------
   Release 1.0.0    | 2026-02-16 | Pablo Hernandez       | Fixed BL
   ----------------------------------------------------------------------------------------------------------------------------------------------------------
#################################################################################################################################################### */

DECLARE
    v_clean text;
    v_tokens text[];
    v_result text[] := '{}';
    v_token text;
    v_suffix_found boolean := false;
    v_states text[] := ARRAY[
        'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA',
        'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
        'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
        'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
        'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY'
    ];
BEGIN
    -- 1️⃣ Uppercase
    v_clean := UPPER(p_address);

    -- 2️⃣ Remove punctuation (keep alphanumeric + space)
    v_clean := regexp_replace(v_clean, '[^A-Z0-9\s]', ' ', 'g');

    -- 3️⃣ Collapse whitespace
    v_clean := regexp_replace(v_clean, '\s+', ' ', 'g');
    v_clean := trim(v_clean);

    -- 4️⃣ Remove trailing ZIP (5 or ZIP+4)
    v_clean := regexp_replace(v_clean, '\m\d{5}(-\d{4})?\M$', '');

    -- 5️⃣ Collapse whitespace again
    v_clean := regexp_replace(v_clean, '\s+', ' ', 'g');
    v_clean := trim(v_clean);

    -- 6️⃣ Tokenize
    v_tokens := string_to_array(v_clean, ' ');

    -- 7️⃣ Remove trailing state abbreviation if present
    IF array_length(v_tokens,1) IS NOT NULL THEN
        IF v_tokens[array_length(v_tokens,1)] = ANY(v_states) THEN
            v_tokens := v_tokens[1:array_length(v_tokens,1)-1];
        END IF;
    END IF;

    -- 8️⃣ Normalize and collect until street suffix found
    FOREACH v_token IN ARRAY v_tokens LOOP

        -- Normalize directionals
        v_token := CASE v_token
            WHEN 'NORTH' THEN 'N'
            WHEN 'SOUTH' THEN 'S'
            WHEN 'EAST' THEN 'E'
            WHEN 'WEST' THEN 'W'
            WHEN 'NORTHEAST' THEN 'NE'
            WHEN 'NORTHWEST' THEN 'NW'
            WHEN 'SOUTHEAST' THEN 'SE'
            WHEN 'SOUTHWEST' THEN 'SW'
            ELSE v_token
        END;

        -- Normalize street suffix
        v_token := CASE v_token
            WHEN 'STREET' THEN 'ST'
            WHEN 'ST' THEN 'ST'
            WHEN 'AVENUE' THEN 'AVE'
            WHEN 'AVE' THEN 'AVE'
            WHEN 'ROAD' THEN 'RD'
            WHEN 'RD' THEN 'RD'
            WHEN 'BOULEVARD' THEN 'BLVD'
            WHEN 'BLVD' THEN 'BLVD'
            WHEN 'DRIVE' THEN 'DR'
            WHEN 'DR' THEN 'DR'
            WHEN 'LANE' THEN 'LN'
            WHEN 'LN' THEN 'LN'
            WHEN 'COURT' THEN 'CT'
            WHEN 'CT' THEN 'CT'
            WHEN 'CIRCLE' THEN 'CIR'
            WHEN 'CIR' THEN 'CIR'
            WHEN 'PLACE' THEN 'PL'
            WHEN 'PL' THEN 'PL'
            WHEN 'TERRACE' THEN 'TER'
            WHEN 'TER' THEN 'TER'
            WHEN 'WAY' THEN 'WAY'
            ELSE v_token
        END;

        -- Add token
        v_result := array_append(v_result, v_token);

        -- If suffix found → stop collecting (ignore units/city/etc)
        IF v_token IN ('ST','AVE','RD','BLVD','DR','LN','CT','CIR','PL','TER','WAY') THEN
            v_suffix_found := true;
            EXIT;
        END IF;

    END LOOP;

    RETURN array_to_string(v_result, ' ');
END;
$$;