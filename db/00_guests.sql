CREATE TABLE guests(
  guest_id SERIAL PRIMARY KEY,
  first_name varchar NOT NULL,
  last_name varchar NOT NULL,
  attending boolean,
  food varchar);
