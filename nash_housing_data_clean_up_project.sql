/*

Cleaning Data with SQL

*/

-- Standardize Date Format

SELECT saledate, saledate::date
FROM housing_data

UPDATE housing_data
SET saledate = saledate::date



-- Populate Property Address Data

SELECT a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress, COALESCE(b.propertyaddress, a.propertyaddress)
FROM housing_data as a
JOIN housing_data as b
	ON a.parcelid = b.parcelid
	AND a.uniqueid != b.uniqueid
WHERE a.propertyaddress = ''

UPDATE 
SET nasha.propertyaddress = COALESCE(nashb.propertyaddress, nashaa.propertyaddress)
FROM housing_data as nasha
JOIN housing_data as nashb 
	ON nasha.parcelid = nashb.parcelid
	AND nasha.uniqueid != nashb.uniqueid
WHERE nasha.propertyaddress = ''



-- Breaking Address into Individual Columns
-- property addresses 

SELECT
SUBSTRING(propertyaddress, 1, strpos(propertyaddress, ',') - 1) as address,
SUBSTRING(propertyaddress, strpos(propertyaddress, ',') + 1) as city
FROM housing_data

ALTER TABLE housing_data
ADD address text

UPDATE housing_data
SET address = SUBSTRING(propertyaddress, 1, strpos(propertyaddress, ',') - 1)

ALTER TABLE housing_data
ADD city text

UPDATE housing_data
SET city = SUBSTRING(propertyaddress, strpos(propertyaddress, ',') + 1)


-- owner address

SELECT owneraddress
FROM housing_data

SELECT 
split_part(owneraddress, ',', 1),
split_part(owneraddress, ',', 2),
split_part(owneraddress, ',', 3)
FROM housing_data

ALTER TABLE housing_data
ADD owner_address text

UPDATE housing_data
SET owner_address = split_part(owneraddress, ',', 1)

ALTER TABLE housing_data
ADD owner_city text

UPDATE housing_data
SET owner_city = split_part(owneraddress, ',', 2)

ALTER TABLE housing_data
ADD owner_state text

UPDATE housing_data
SET owner_state = split_part(owneraddress, ',', 3)



-- Change Y and N to Yes/No in "Sold as Vacant" field

SELECT DISTINCT soldasvacant, COUNT(soldasvacant)
FROM housing_data
GROUP BY soldasvacant
ORDER BY 2

SELECT soldasvacant,
	CASE
		WHEN soldasvacant = 'Y' THEN 'Yes'
		WHEN soldasvacant = 'N' THEN 'No'
		ELSE soldasvacant
	END as vacant
FROM housing_data

UPDATE housing_data
	SET soldasvacant = 	CASE
		WHEN soldasvacant = 'Y' THEN 'Yes'
		WHEN soldasvacant = 'N' THEN 'No'
		ELSE soldasvacant
	END



-- Remove Duplicates

WITH row_num_cte as (
	SELECT uniqueid FROM
(SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY parcelid, propertyaddress, saleprice, saledate, legalreference
		ORDER BY uniqueid
	) row_num
FROM housing_data
 ) s
	WHERE row_num > 1
-- ORDER BY parcelid
)
DELETE
FROM housing_data
WHERE uniqueid IN (SELECT * FROM row_num_cte)



-- Delete Unused Columns

ALTER TABLE housing_data
DROP COLUMN owneraddress, 
DROP COLUMN taxdistrict, 
DROP COLUMN propertyaddress, 
DROP COLUMN legalreference