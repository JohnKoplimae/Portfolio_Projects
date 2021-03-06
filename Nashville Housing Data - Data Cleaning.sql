SELECT * FROM nash_housing;

-- Cleaning Data with SQL queries in Oracle.

-- Modify Date format from YY-MM-DD to YYYY-MM-DD

SELECT saledate, TO_CHAR(TO_DATE(saledate, 'YY-MM-DD'), 'YYYY-MM-DD') FROM nash_housing;

ALTER SESSION SET nls_date_format = 'YYYY-MM-DD';

SELECT saledate FROM nash_housing;

-- Populate Property Address Data
-- Removing NULL values for propertyaddress using parcelid. Since when two parcelid's are the same, so is the propertyaddress.

SELECT * FROM nash_housing
WHERE propertyaddress IS NUll;

SELECT A.parcelid, A.propertyaddress, B.parcelid, B.propertyaddress, NVL(A.propertyaddress, B.propertyaddress)
FROM nash_housing A
JOIN nash_housing B 
    ON A.parcelid = B.parcelid
    AND A.uniqueid_ <> B.uniqueid_
WHERE A.propertyaddress IS NULL;

UPDATE nash_housing n
    SET propertyaddress = (SELECT n2.propertyaddress
                            FROM nash_housing n2
                            WHERE n2.parcelid = n.parcelid
                            AND n2.uniqueid_ <> n.uniqueid_
                            AND rownum = 1
                            )
WHERE n.propertyaddress IS NULL
AND EXISTS (SELECT n2.propertyaddress
            FROM nash_housing n2
            WHERE n2.parcelid = n.parcelid
            AND n2.uniqueid_ <> n.uniqueid_
            );

-- Breaking out Property Address into individual columns (Address, City)

SELECT SUBSTR(propertyaddress, 0, INSTR(propertyaddress, ',')-1) AS Address, 
SUBSTR(propertyaddress, INSTR(propertyaddress, ',')+1, LENGTH(propertyaddress)) AS City 
FROM nash_housing;

--UPDATE TABLE for Property Adress
ALTER TABLE nash_housing
ADD Property_Split_Address varchar2(256);

UPDATE nash_housing
SET Property_Split_Address = SUBSTR(propertyaddress, 0, INSTR(propertyaddress, ',')-1);

ALTER TABLE nash_housing
ADD Property_Split_City varchar2(256);

UPDATE nash_housing
SET Property_Split_City = SUBSTR(propertyaddress, INSTR(propertyaddress, ',')+1, LENGTH(propertyaddress));
COMMIT;

SELECT Property_Split_Address, Property_Split_City FROM nash_housing;
SELECT * FROM nash_housing;

-- Breaking out Owner Address into individual columns (Address, City, State)

SELECT regexp_substr(owneraddress, '(.*?)(,|$)', 1, 1, NULL, 1), 
regexp_substr(owneraddress, '(.*?)(,|$)', 1, 2, NUll, 1),
regexp_substr(owneraddress, '(.*?)(,|$)', 1, 3, NUll, 1)
FROM nash_housing;

--UPDATE TABLE for Owner Address
ALTER TABLE nash_housing
ADD Owner_Split_Address varchar2(256);

ALTER TABLE nash_housing
ADD Owner_Split_City varchar2(256);

ALTER TABLE nash_housing
ADD Owner_Split_State varchar2(256);

UPDATE nash_housing
SET Owner_Split_Address = regexp_substr(owneraddress, '(.*?)(,|$)', 1, 1, NULL, 1);

UPDATE nash_housing
SET Owner_Split_City = regexp_substr(owneraddress, '(.*?)(,|$)', 1, 2, NUll, 1);

UPDATE nash_housing
SET Owner_Split_State = regexp_substr(owneraddress, '(.*?)(,|$)', 1, 3, NUll, 1);
COMMIT;

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(soldasvacant), COUNT(soldasvacant) FROM nash_housing
GROUP BY soldasvacant
ORDER BY 2;

SELECT soldasvacant, 
CASE WHEN soldasvacant = 'Y' THEN 'Yes'
    WHEN soldasvacant = 'N' THEN 'No'
    ELSE soldasvacant
    END
FROM nash_housing;

UPDATE nash_housing
SET soldasvacant = CASE WHEN soldasvacant = 'Y' THEN 'Yes'
    WHEN soldasvacant = 'N' THEN 'No'
    ELSE soldasvacant
    END;
    
-- Find Duplicates
-- Needed an alias for the table on select everything.
WITH RowNumCTE AS (
SELECT A.*, ROW_NUMBER() OVER(
    PARTITION BY parcelid,
                 propertyaddress,
                 saleprice,
                 saledate,
                 legalreference
                 ORDER BY 
                    uniqueid_
                    ) AS row_num FROM nash_housing A
)
SELECT * FROM RowNumCTE
WHERE row_num > 1
ORDER BY uniqueid_;

-- Remove unneeded columns

ALTER TABLE nash_housing
DROP COLUMN owneraddress, taxdistrict, propertyaddress, saledate;
