-- Drop table if it exists
DROP TABLE IF EXISTS mailed;

-- Create the table with the correct structure
CREATE TABLE mailed (
  id SERIAL PRIMARY KEY,
  full_name VARCHAR,
  first_name VARCHAR,
  last_name VARCHAR,
  mailing_address VARCHAR NOT NULL,
  mailing_city VARCHAR NOT NULL,
  mailing_state VARCHAR NOT NULL,
  mailing_zip VARCHAR NOT NULL,
  property_address VARCHAR NOT NULL,
  property_city VARCHAR NOT NULL,
  property_state VARCHAR NOT NULL,
  property_zip VARCHAR NOT NULL,
  checkval DECIMAL(15,2),
  mail_month VARCHAR,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Add indexes for better search performance
CREATE INDEX idx_mailed_mailing_address ON mailed (mailing_address);
CREATE INDEX idx_mailed_property_address ON mailed (property_address);
CREATE INDEX idx_mailed_mailing_zip ON mailed (mailing_zip);
CREATE INDEX idx_mailed_property_zip ON mailed (property_zip);
CREATE INDEX idx_mailed_full_name ON mailed (full_name);
CREATE INDEX idx_mailed_last_name ON mailed (last_name);
