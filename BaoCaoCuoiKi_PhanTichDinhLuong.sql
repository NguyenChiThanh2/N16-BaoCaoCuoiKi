--Recency (R):
-- Lấy ngày đặt hàng cuối cùng của mỗi khách hàng ở khu vực Bắc Mỹ.
SELECT 
    c.CustomerID, 
    MAX(soh.OrderDate) AS LastPurchaseDate
FROM 
    Sales.Customer c
JOIN 
    Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
JOIN 
    Sales.SalesTerritory st ON c.TerritoryID = st.TerritoryID
WHERE 
    st.CountryRegionCode = 'US' or st.CountryRegionCode = 'CA'
GROUP BY 
    c.CustomerID

--Frequency (F):
-- Đếm số lượng đơn đặt hàng của mỗi khách hàng ở khu vực Bắc Mỹ.
SELECT 
    c.CustomerID, 
    COUNT(DISTINCT soh.SalesOrderID) AS TotalOrders
FROM 
    Sales.Customer c
JOIN 
    Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
JOIN 
    Sales.SalesTerritory st ON c.TerritoryID = st.TerritoryID
WHERE 
    st.CountryRegionCode = 'US' or st.CountryRegionCode = 'CA' 
GROUP BY 
    c.CustomerID

--Monetary (M):
-- Tính tổng số tiền mỗi khách hàng ở khu vực Bắc Mỹ đã tiêu.
SELECT 
    c.CustomerID, 
    SUM(sod.UnitPrice * sod.OrderQty) AS TotalSpent
FROM 
    Sales.Customer c
JOIN 
    Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
JOIN 
    Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN 
    Sales.SalesTerritory st ON c.TerritoryID = st.TerritoryID
WHERE 
    st.CountryRegionCode = 'US' or st.CountryRegionCode = 'CA' 
GROUP BY 
    c.CustomerID

-- ==> Kết hợp dữ liệu RFM
SELECT 
    r.CustomerID,
    r.LastPurchaseDate,
    f.TotalOrders,
    m.TotalSpent
FROM 
    (
        SELECT 
            c.CustomerID, 
            MAX(soh.OrderDate) AS LastPurchaseDate
        FROM 
            Sales.Customer c
        JOIN 
            Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
        GROUP BY 
            c.CustomerID
    ) r
JOIN 
    (
        SELECT 
            c.CustomerID, 
            COUNT(soh.SalesOrderID) AS TotalOrders -- Thay đổi đếm các đơn hàng
        FROM 
            Sales.Customer c
        JOIN 
            Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
        GROUP BY 
            c.CustomerID
    ) f ON r.CustomerID = f.CustomerID
JOIN 
    (
        SELECT 
            c.CustomerID, 
            SUM(sod.UnitPrice * sod.OrderQty) AS TotalSpent
        FROM 
            Sales.Customer c
        JOIN 
            Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
        JOIN 
            Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
        GROUP BY 
            c.CustomerID
    ) m ON r.CustomerID = m.CustomerID

--=========================================

-- Tính điểm RFM
WITH Recency AS (
    SELECT 
        c.CustomerID, 
        DATEDIFF(DAY, MAX(soh.OrderDate), GETDATE()) AS Recency
    FROM 
        Sales.Customer c
    JOIN 
        Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    JOIN 
        Sales.SalesTerritory st ON c.TerritoryID = st.TerritoryID
    WHERE 
        st.CountryRegionCode = 'US' or st.CountryRegionCode = 'CA' 
    GROUP BY 
        c.CustomerID
),
Frequency AS (
    SELECT 
        c.CustomerID, 
        COUNT(DISTINCT soh.SalesOrderID) AS Frequency
    FROM 
        Sales.Customer c
    JOIN 
        Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    JOIN 
        Sales.SalesTerritory st ON c.TerritoryID = st.TerritoryID
    WHERE 
        st.CountryRegionCode = 'US' or st.CountryRegionCode = 'CA'
    GROUP BY 
        c.CustomerID
),
Monetary AS (
    SELECT 
        c.CustomerID, 
        SUM(sod.UnitPrice * sod.OrderQty) AS Monetary
    FROM 
        Sales.Customer c
    JOIN 
        Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    JOIN 
        Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
    JOIN 
        Sales.SalesTerritory st ON c.TerritoryID = st.TerritoryID
    WHERE 
        st.CountryRegionCode = 'US' or st.CountryRegionCode = 'CA' -- Chỉ lấy thông tin của khách hàng ở Bắc Mỹ
    GROUP BY 
        c.CustomerID
)
SELECT 
    r.CustomerID,
    r.Recency,
    f.Frequency,
    m.Monetary,
    NTILE(5) OVER (ORDER BY r.Recency desc) AS RFM_Recency,
    NTILE(5) OVER (ORDER BY f.Frequency ) AS RFM_Frequency,
    NTILE(5) OVER (ORDER BY m.Monetary ) AS RFM_Monetary,
    CONVERT(VARCHAR(10), NTILE(5) OVER (ORDER BY r.Recency desc)) + 
    CONVERT(VARCHAR(10), NTILE(5) OVER (ORDER BY f.Frequency)) + 
    CONVERT(VARCHAR(10), NTILE(5) OVER (ORDER BY m.Monetary )) AS RFM_Score
FROM 
    Recency r
JOIN 
    Frequency f ON r.CustomerID = f.CustomerID
JOIN 
    Monetary m ON r.CustomerID = m.CustomerID

