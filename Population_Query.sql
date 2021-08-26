
/*   SQL Queries for Data Cleaning (PopulationData Table)  */

SELECT *
FROM PopulationProject.dbo.PopulationData


---------------------------------------------------------------------------

-- Breaking DATE_DESC column into pop_date and pop_description columns --


-- Extract description ( as pop_description column) from DATE_DESC column

Select DATE_DESC, SUBSTRING(DATE_DESC, CHARINDEX(' ', DATE_DESC)+1, LEN(DATE_DESC)) AS pop_description
FROM PopulationProject.dbo.PopulationData


-- Add pop_description column to PopulationData Table

ALTER TABLE PopulationProject.dbo.PopulationData
Add pop_description  Nvarchar(255);

Update PopulationProject.dbo.PopulationData
SET pop_description = SUBSTRING(DATE_DESC, CHARINDEX(' ', DATE_DESC)+1, LEN(DATE_DESC))


------------------------------------------------------------------------------

-- Extract date ( as pop_date column) from DATE_DESC column

SELECT DATE_DESC, CONVERT(DATE, SUBSTRING(DATE_DESC, 0, CHARINDEX(' ', DATE_DESC))) AS pop_date
FROM PopulationProject.dbo.PopulationData


-- Add pop_date column to PopulationData Table

ALTER TABLE PopulationProject.dbo.PopulationData
Add pop_date Date;

Update PopulationProject.dbo.PopulationData
SET pop_date = CONVERT(DATE, SUBSTRING(DATE_DESC, 0, CHARINDEX(' ', DATE_DESC)))


------------------------------------------------------------------------------

-- Extract Year (as pop_year column) from pop_date column

SELECT pop_date, YEAR(pop_date) AS pop_year
FROM PopulationProject.dbo.PopulationData


-- Add pop_year column to PopulationData Table

ALTER TABLE PopulationProject.dbo.PopulationData
Add pop_year int;

Update PopulationProject.dbo.PopulationData
SET pop_year = YEAR(pop_date)


---------------------------------------------------------------------------------

-- Extract month (as pop_month column) from pop_date column

SELECT pop_date, FORMAT(pop_date, 'MMMM') AS pop_month
FROM PopulationProject.dbo.PopulationData


-- Add pop_month column to PopulationData Table

ALTER TABLE PopulationProject.dbo.PopulationData
Add pop_month nvarchar(255);

Update PopulationProject.dbo.PopulationData
SET pop_month = FORMAT(pop_date, 'MMMM')

----------------------------------------------------------------------

-- Extract day (as pop_day column) from pop_date column

SELECT pop_date, FORMAT(pop_date, 'dddd') AS pop_day
FROM PopulationProject.dbo.PopulationData


-- Add pop_month column to PopulationData Table

ALTER TABLE PopulationProject.dbo.PopulationData
Add pop_day nvarchar(255);

Update PopulationProject.dbo.PopulationData
SET pop_day = FORMAT(pop_date, 'dddd')


----------------------------------------------------------------------

SELECT *
FROM PopulationProject.dbo.PopulationData


-- Breaking GEONAME column into pop_county and pop_state columns --


-- Extract county name (as pop_county column) from GEONAME column

Select GEONAME, SUBSTRING(GEONAME, 0, CHARINDEX(',', GEONAME)) AS pop_county
FROM PopulationProject.dbo.PopulationData


-- Add pop_county column to PopulationData Table

ALTER TABLE PopulationProject.dbo.PopulationData
Add pop_county Nvarchar(255);

Update PopulationProject.dbo.PopulationData
SET pop_county = SUBSTRING(GEONAME, 0, CHARINDEX(',', GEONAME))

----------------------------------------------------------------------------

-- Extract state name (as pop_state column) from GEONAME column

Select GEONAME, SUBSTRING(GEONAME, CHARINDEX(',', GEONAME)+2, LEN(GEONAME)) AS pop_state
FROM PopulationProject.dbo.PopulationData


-- Add pop_state column to PopulationData Table

ALTER TABLE PopulationProject.dbo.PopulationData
Add pop_state Nvarchar(255);

Update PopulationProject.dbo.PopulationData
SET pop_state = SUBSTRING(GEONAME, CHARINDEX(',', GEONAME)+2, LEN(GEONAME))


---------------------------------------------------------------------------

--  Delete unused columns (uncleaned ones)

SELECT *
FROM PopulationProject.dbo.PopulationData


ALTER TABLE PopulationProject.dbo.PopulationData
DROP COLUMN DATE_DESC, GEONAME

-------------------------------------------------------

-- Remove duplicates 

WITH CTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY 
                pop_number, 
				pop_density, 
				state_number, 
				pop_description,
				pop_date,
				pop_year,
				pop_month,
				pop_day,
				pop_county,
				pop_state
            ORDER BY 
                pop_number
        ) row_num
     FROM PopulationProject.dbo.PopulationData
)
DELETE FROM CTE
WHERE row_num > 1;



SELECT *
FROM PopulationProject.dbo.PopulationData



-- Dealing with NULL values (pop_density column)

SELECT *
FROM PopulationProject.dbo.PopulationData
WHERE pop_density is Null

-- We can see that all Null values belong to 'Puerto Rico Commonwealth' state 
-- and there are some miss-typed counties too from the same state
-- We can verify our hypothese by running this two queries :

SELECT COUNT(pop_county)
FROM PopulationProject.dbo.PopulationData
WHERE pop_density is Null;

SELECT COUNT(*)
FROM PopulationProject.dbo.PopulationData
WHERE pop_state = 'Puerto Rico Commonwealth'


/* To Deal with those NULL values we can choose between 2 solutions:

=> The first One (easy but not recommended): 
  Deleting those rows and this will exclude the entire state 'Puerto Rico Commonwealth' from any further analysis

=> The Second One (need some online search but highly recommended): 
  We can look for another dataset contain density for same counties and state (hard to find compatible one)
  Or, We can calculate the density from population number by the formula that link density with population number:
  
  The Formula For Calculating Population Density is Dp= N/A. 
   * Dp: is the density of population, (pop_density in our case)
   * N: is the total population as a number of people (pop_number in our case)
   * A: is the land area(mile square) covered by that population (county_mile_square)

   Now, to fill those null values and fix miss-typed counties, 
   we will use a CleanedCountyPR table containig (pop_county, cleaned_county, county_mile_square) 
*/
-- For fixing miss-typed counties (using CleanedCountyPR table):

Update a  
SET a.pop_county = b.cleaned_county
FROM PopulationProject.dbo.PopulationData as a 
INNER JOIN PopulationProject.dbo.CleanedCountyPR as b
on a.pop_county = b.pop_county
WHERE a.pop_density is null


-- For fixing Null values by calculating density (pop_number * county_mile_square)

Update a 
SET a.pop_density = (a.pop_number * b.county_mile_square)
FROM PopulationProject.dbo.PopulationData as a 
INNER JOIN PopulationProject.dbo.CleanedCountyPR as b
on a.pop_county = b.cleaned_county
WHERE a.pop_density is null


-- Check if all Null values are fixed

SELECT COUNT(*)
FROM PopulationProject.dbo.PopulationData
WHERE pop_density is null

---------------------------------------

SELECT *
FROM PopulationProject.dbo.PopulationData

-- End