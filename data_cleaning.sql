/*
Data Cleaninf in SQL queries
*/

select *
from PortfolioProject.dbo.NasgvilleHouing


---------Standardize Date format

select SaleDateConverted, CONVERT(date, SaleDate)
from PortfolioProject.dbo.NasgvilleHouing

update NasgvilleHouing
set SaleDate = CONVERT(date, SaleDate)

alter table NasgvilleHouing
add SaleDateConverted date

update NasgvilleHouing
set SaleDateConverted = CONVERT(date, SaleDate)
----------------------------------------------------------------------------------------------------------------------------------


--Populate Property Address data


select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, isnull(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject.dbo.NasgvilleHouing as a
join PortfolioProject.dbo.NasgvilleHouing as b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
--where a.PropertyAddress is null

update a
set PropertyAddress = isnull(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject.dbo.NasgvilleHouing as a
join PortfolioProject.dbo.NasgvilleHouing as b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null
---------------------------------------------------------------------------------------------------------------------------------


--Breaking out address into individual columns(address, city, state)

------------------------------------------Using SUBSTRING

select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
from PortfolioProject.dbo.NasgvilleHouing

alter table NasgvilleHouing
add PropertySplitAddress nvarchar(255)

update NasgvilleHouing
set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

alter table NasgvilleHouing
add PropertySplitCity nvarchar(255)

update NasgvilleHouing
set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


-------------------------------------------------Using PARSENAME

select 
PARSENAME(REPLACE(OwnerAddress, ',','.'),3),
PARSENAME(REPLACE(OwnerAddress, ',','.'),2),
PARSENAME(REPLACE(OwnerAddress, ',','.'),1)
from PortfolioProject.dbo.NasgvilleHouing

alter table NasgvilleHouing
add OwnerSplitAddress nvarchar(255)

update NasgvilleHouing
set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'),3)

alter table NasgvilleHouing
add OwnerSplitCity nvarchar(255)

update NasgvilleHouing
set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.'),2)

alter table NasgvilleHouing
add OwnerSplitState nvarchar(255)

update NasgvilleHouing
set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.'),1)

-------------------------------------------------------------------------------------------------------------------

--Change Y and N to YES and NO in "SoldAsVacant" field

select SoldAsVacant,
case
	when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
	end
from PortfolioProject.dbo.NasgvilleHouing

update NasgvilleHouing
set SoldAsVacant = case
					when SoldAsVacant = 'Y' then 'Yes'
					when SoldAsVacant = 'N' then 'No'
					else SoldAsVacant
					end
-----------------------------------------------------------------------------------------------------------------------------


-- Remove duplicates

with RowNumCTE as(
select *,
ROW_NUMBER() over(
Partition by ParcelID,
			PropertyAddress,
			SaleDate,
			SalePrice,
			LegalReference
			order by UniqueID
) row_num
from PortfolioProject.dbo.NasgvilleHouing
)
delete
from RowNumCTE
where row_num > 1
----------------------------------------------------------------------------------------------------------------------------------------------

--Remove unused columns

alter table PortfolioProject.dbo.NasgvilleHouing
drop column PropertyAddress, TaxDistrict, OwnerAddress 
