CREATE TABLE parties (
    party_id SERIAL PRIMARY KEY,
    responded boolean DEFAULT false NOT NULL,
    has_plus_one boolean NOT NULL,
    extra_family boolean NOT NULL
);

ALTER TABLE guests ADD COLUMN party_id integer;
