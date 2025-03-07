WITH PolicyMatch AS
(
    SELECT 
        pt.po_No,
        pt.Pev_CreatedAt,
        pt.Pev_PortfolioResponsibleCode,
        pt.pev_Id,
        p.Key_Policy,
        p.Bnd_Dt,
        p.Pln_End_Dt,
        pf.PaymentDate,
        p.Vrsn,
        p.Term,
        p.Vld_Fm_Tms,
        p.Vld_To_Tms,
        pf.product_Name,
        s.Org_Lvl_Nm,
        p.Agrm_Sts_Cd,
        p.Cncl_Dt,
        p.Rnew_Dt,
        pf.Annual_Premium,
        ROW_NUMBER() OVER 
        (
            PARTITION BY pt.po_No, pt.Pev_PortfolioResponsibleCode,
            p.Bnd_Dt, p.Pln_End_Dt,pf.Key_Policy
            ORDER BY pt.Pev_CreatedAt DESC
        ) AS PolicyMatch_rn
    FROM 
        Policy_Transactions AS pt
		INNER JOIN 
        Policy AS p ON pt.po_No = p.Ext_Refr
		INNER JOIN 
        Portfolio AS pf ON p.Key_Policy = pf.Key_Policy
		INNER JOIN 
        Sales_Org AS s ON pf.Key_SS_Org = s.Key_SS_Org
    WHERE 
			YEAR(p.Bnd_Dt) = 2024 AND MONTH(p.Bnd_Dt) BETWEEN 1 AND 8
        AND 
			(
				pt.pev_CreatedAt >= p.Bnd_Dt 
				AND 
				pt.pev_CreatedAt <= p.Pln_End_Dt
			)
        AND 
			pf.Payment_Status = 'Paid' 
        AND 
			(
				pf.product_Name BETWEEN 'Product 1' AND 'Product 8'
				OR 
				pf.product_Name BETWEEN 'Product 13' AND 'Product 31'
			)
),
PortfolioResposivecode_Check AS 
(
    SELECT 
        po_No,
        COUNT(DISTINCT Pev_PortfolioResponsibleCode) AS PortfolioCode_Check
    FROM 
        PolicyMatch
    GROUP BY 
        po_No
),
CommissionCalc AS 
(
    SELECT 
        pm.*,
        pc.PortfolioCode_Check,
        CASE
            WHEN pm.Agrm_Sts_Cd = 'CANCEL' 
            THEN DATEDIFF(day, pm.Bnd_Dt, pm.Cncl_Dt)
            ELSE NULL
        END AS Clawback_Calc,
        DATEDIFF(day, pm.Bnd_Dt, DATEADD(day, 1, pm.Pln_End_Dt)) AS TotalDays
    FROM 
        PolicyMatch pm
		INNER JOIN 
        PortfolioResposivecode_Check pc ON pm.po_No = pc.po_No
    WHERE 
			PolicyMatch_rn = 1 
		AND
			pc.PortfolioCode_Check=1
		AND
			(
				(pm.Pev_PortfolioResponsibleCode = 'WILDWEST-2' AND pm.Org_Lvl_Nm = 'Inbound') 
				OR 
				(pm.Pev_PortfolioResponsibleCode = 'WILDWEST-3' AND pm.Org_Lvl_Nm IN ('Outbound', 'Internet'))
			)
		AND
			pm.Vld_Fm_Tms<='2024-08-31'
			AND 
			pm.Vld_To_Tms>'2024-08-31'
),
Final_Commission AS
(
    SELECT 
        cc.*,
        CASE
            WHEN ROW_NUMBER() OVER (ORDER BY cc.Bnd_Dt) <= 1500 
            THEN cc.Annual_Premium * 0.12
            ELSE cc.Annual_Premium * 0.14
        END AS Commission_Amt
    FROM 
        CommissionCalc cc
),
Final_Calculation AS
(
	SELECT 
		fc.*, 
		ROW_NUMBER() OVER (ORDER BY fc.Bnd_Dt) AS rn,
			CASE
				WHEN fc.Clawback_Calc IS NOT NULL THEN 
					CAST(
						ROUND(
								fc.Commission_Amt - ((fc.Commission_Amt / fc.TotalDays) * fc.Clawback_Calc),2
							 ) AS DECIMAL(10,2)
						)
				ELSE 0
			END AS Commission_Return,
		CASE
			WHEN fc.Commission_Amt IS NOT NULL THEN DATEADD(MONTH, 1, fc.Bnd_Dt)
			WHEN fc.Clawback_Calc IS NOT NULL THEN DATEADD(MONTH, 1, fc.Cncl_Dt)
		END AS Report_Dt
	FROM 
		Final_Commission fc
),
Policies AS (
    SELECT
        YEAR(f.Bnd_Dt) AS Year,
        MONTH(f.Bnd_Dt) AS Month,
        COUNT(f.po_No) AS Total_Policies,
        SUM(f.Annual_Premium) AS Total_Annual_Premium
    FROM 
        Final_Calculation f
	GROUP BY 
        YEAR(f.Bnd_Dt), MONTH(f.Bnd_Dt)
),
Commissions AS 
(
    SELECT
        YEAR(f.Report_Dt) AS Year, 
        MONTH(f.Report_Dt) AS Month,    
        SUM(f.Commission_Amt) AS Total_Commission, 
        SUM(f.Commission_Return) AS Clawback_Returns
    FROM 
        Final_Calculation f
    GROUP BY 
        YEAR(f.Report_Dt), MONTH(f.Report_Dt)
)
SELECT 
    p.Year,
    p.Month,
    p.Total_Policies,
    p.Total_Annual_Premium,
    COALESCE(c.Total_Commission, 0) AS Total_Commission,
    COALESCE(c.Clawback_Returns, 0) AS Clawback_Returns
FROM 
    Policies p
	LEFT JOIN
    Commissions c ON p.Year = c.Year AND p.Month = c.Month
ORDER BY 
    p.Year, p.Month;