-- no dependency tables

CREATE TABLE REGION (
    region_id INT AUTO_INCREMENT PRIMARY KEY,
    region_name VARCHAR(100) NOT NULL,
    country VARCHAR(50) NOT NULL,
    total_population INT
);

CREATE TABLE DEMOGRAPHIC_PROFILE (
    demographic_id INT AUTO_INCREMENT PRIMARY KEY,
    income_bracket VARCHAR(30) NOT NULL,
    age_group VARCHAR(30) NOT NULL,
    vulnerability_flag BOOLEAN NOT NULL
);

CREATE TABLE ENERGY_SUPPLIER (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    ofgem_license_code VARCHAR(30) UNIQUE NOT NULL,
    support_scheme_enrolled BOOLEAN NOT NULL
);

CREATE TABLE COMMODITY_SHOCK (
    shock_id INT AUTO_INCREMENT PRIMARY KEY,
    event_name VARCHAR(150) NOT NULL,
    commodity_type VARCHAR(20) NOT NULL,
    shock_start_date DATE NOT NULL,
    shock_end_date DATE,
    wholesale_price_index DECIMAL(10,3) NOT NULL
);

CREATE TABLE CENTRAL_BANK_POLICY (
    policy_id INT AUTO_INCREMENT PRIMARY KEY,
    effective_date DATE NOT NULL,
    base_interest_rate DECIMAL(8,4) NOT NULL,
    mortgage_stress_index DECIMAL(8,4)
);

-- tables with simple FK

CREATE TABLE HOUSEHOLD (
    household_id INT AUTO_INCREMENT PRIMARY KEY,
    region_id INT NOT NULL,
    postcode VARCHAR(10) NOT NULL,
    dwelling_type VARCHAR(50),
    occupant_count INT,
    housing_tenure VARCHAR(30),
    FOREIGN KEY (region_id) REFERENCES REGION(region_id)
);

CREATE TABLE MACROECONOMIC_METRIC (
    metric_id INT AUTO_INCREMENT PRIMARY KEY,
    region_id INT NOT NULL,
    recording_date DATE NOT NULL,
    headline_cpi DECIMAL(8,3) NOT NULL,
    inflation_rate DECIMAL(8,3) NOT NULL,
    energy_cpi_weight DECIMAL(8,4),
    FOREIGN KEY (region_id) REFERENCES REGION(region_id)
);

-- doble FK (energy_bill)

CREATE TABLE ENERGY_BILL (
    bill_id INT AUTO_INCREMENT PRIMARY KEY,
    household_id INT NOT NULL,
    supplier_id INT NOT NULL,
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    kwh_consumed DECIMAL(10,2) NOT NULL,
    price_cap_rate DECIMAL(10,4),
    total_amount_gbp DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (household_id) REFERENCES HOUSEHOLD(household_id),
    FOREIGN KEY (supplier_id) REFERENCES ENERGY_SUPPLIER(supplier_id)
);

-- composed PK

CREATE TABLE HOUSEHOLD_DEMOGRAPHIC (
    household_id INT NOT NULL,
    demographic_id INT NOT NULL,
    assigned_date DATE NOT NULL,
    PRIMARY KEY (household_id, demographic_id),
    FOREIGN KEY (household_id) REFERENCES HOUSEHOLD(household_id),
    FOREIGN KEY (demographic_id) REFERENCES DEMOGRAPHIC_PROFILE(demographic_id)
);

CREATE TABLE SHOCK_IMPACT_LOG (
    shock_id INT NOT NULL,
    metric_id INT NOT NULL,
    impact_type VARCHAR(50) NOT NULL,
    impact_value DECIMAL(10,4),
    PRIMARY KEY (shock_id, metric_id),
    FOREIGN KEY (shock_id) REFERENCES COMMODITY_SHOCK(shock_id),
    FOREIGN KEY (metric_id) REFERENCES MACROECONOMIC_METRIC(metric_id)
);

CREATE TABLE HOUSEHOLD_POLICY_IMPACT (
    policy_id INT NOT NULL,
    household_id INT NOT NULL,
    borrowing_cost_gbp DECIMAL(10,2),
    mortgage_rate DECIMAL(8,4),
    PRIMARY KEY (policy_id, household_id),
    FOREIGN KEY (policy_id) REFERENCES CENTRAL_BANK_POLICY(policy_id),
    FOREIGN KEY (household_id) REFERENCES HOUSEHOLD(household_id)
);
