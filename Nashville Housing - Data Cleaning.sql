/*

Nashville Housing - Cleaning Data in SQL Queries

*/


Select *
From PortfolioProject.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format


--Select SaleDateConverted, CONVERT(Date,saleDate)
--From PortfolioProject.dbo.NashvilleHousing


Alter Table PortfolioProject.dbo.NashvilleHousing
Add SaleDateConverted Date;

Update PortfolioProject.dbo.NashvilleHousing
Set SaleDateConverted = CONVERT(Date,SaleDate)





 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address Data

Select *
From PortfolioProject.dbo.NashvilleHousing
--Where PropertyAddress is null
Order by ParcelID


Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
Join PortfolioProject.dbo.NashvilleHousing b
	On a.ParcelID =b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
Join PortfolioProject.dbo.NashvilleHousing b
	On a.ParcelID =b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null





--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


--Showing changes to the PropertyAddress Column

Select PropertyAddress
From PortfolioProject.dbo.NashvilleHousing

Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address
From PortfolioProject.dbo.NashvilleHousing



Alter Table PortfolioProject.dbo.NashvilleHousing
Add PropertySplitAddress nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
Set PropertySplitAddress  = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) 



Alter Table PortfolioProject.dbo.NashvilleHousing
Add PropertySplitCity nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
Set PropertySplitCity  = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) 




--Showing changes to the OwnerAddress Column

Select OwnerAddress
From PortfolioProject.dbo.NashvilleHousing

Select
PARSENAME(Replace(OwnerAddress,',', '.'), 3),
PARSENAME(Replace(OwnerAddress,',', '.'), 2),
PARSENAME(Replace(OwnerAddress,',', '.'), 1)
From PortfolioProject.dbo.NashvilleHousing



Alter Table PortfolioProject.dbo.NashvilleHousing
Add OwnerSplitAddress nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
Set OwnerSplitAddress  = PARSENAME(Replace(OwnerAddress,',', '.'), 3) 


Alter Table PortfolioProject.dbo.NashvilleHousing
Add OwnerSplitCity nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
Set OwnerSplitCity  = PARSENAME(Replace(OwnerAddress,',', '.'), 2)


Alter Table PortfolioProject.dbo.NashvilleHousing
Add OwnerSplitState nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
Set OwnerSplitState  = PARSENAME(Replace(OwnerAddress,',', '.'), 1) 







--------------------------------------------------------------------------------------------------------------------------

-- Changing Y and N to Yes and No in "Sold as Vacant" field

Select Distinct (SoldAsVacant), count(SoldAsVacant)
From PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
Order by 2


Select SoldAsVacant,
CASE When SoldAsVacant ='Y' then 'Yes'
	 When SoldAsVacant ='N' then 'No'
	 Else SoldAsVacant
End
From PortfolioProject.dbo.NashvilleHousing

Update PortfolioProject.dbo.NashvilleHousing
Set SoldAsVacant  = CASE When SoldAsVacant ='Y' then 'Yes'
	 When SoldAsVacant ='N' then 'No'
	 Else SoldAsVacant
End





-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Removing Duplicates


With Row_NumCTE  AS(
Select *,
	ROW_NUMBER()  OVER (
	Partition By ParcelId,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order By uniqueID) row_num

From PortfolioProject.dbo.NashvilleHousing
)
Select*
From Row_NumCTE
Where row_num > 1






---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

Select *
From PortfolioProject.dbo.NashvilleHousing

Alter Table PortfolioProject.dbo.NashvilleHousing
Drop Column OwnerAddress, TaxDistrict, PropertyAddress

Alter Table PortfolioProject.dbo.NashvilleHousing
Drop Column SaleDate




-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------


