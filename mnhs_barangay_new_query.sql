
CREATE DATABASE marigondon_profiling_db;

CREATE SEQUENCE SYS_USER_ID_SEQ START 1001;


CREATE TYPE role_type_enum AS ENUM(
    'Staff',
    'Admin',
    'Super Admin'
    );


CREATE TABLE SYSTEM_ACCOUNT (
                                SYS_ID SERIAL PRIMARY KEY,
                                SYS_USER_ID INT UNIQUE DEFAULT NEXTVAL('SYS_USER_ID_SEQ'),
                                SYS_PASSWORD VARCHAR(6) NOT NULL,
                                SYS_FNAME VARCHAR(50) NOT NULL,
                                SYS_MNAME VARCHAR(50),
                                SYS_LNAME VARCHAR(50) NOT NULL,
                                SYS_ROLE role_type_enum,
                                SYS_IS_ACTIVE BOOLEAN DEFAULT TRUE,
                                SYS_DATE_ENCODED TIMESTAMP DEFAULT CURRENT_TIMESTAMP

);

CREATE TYPE action_type_enum AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'LOGIN',
    'LOGOUT'
    );

CREATE TABLE SYSTEM_ACTIVITY_LOG(
                                    ACT_ID SERIAL PRIMARY KEY,
                                    ACT_TIMESTAMP TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                    ACT_ACTION_TYPE action_type_enum,
                                    ACT_TABLE_NAME VARCHAR(50) NOT NULL,
                                    ACT_ENTITY_ID INT,
                                    ACT_DESCRIPTION TEXT,
                                    SYS_ID INT NOT NULL REFERENCES SYSTEM_ACCOUNT(SYS_ID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Table: SITIO
CREATE TABLE SITIO (
                       SITIO_ID SERIAL PRIMARY KEY,
                       SITIO_NAME VARCHAR(100) NOT NULL
);

CREATE TABLE CLASSIFICATION_HEALTH_RISK(
                                           CLAH_ID SERIAL PRIMARY KEY,
                                           CLAH_CLASSIFICATION_NAME VARCHAR(50) NOT NULL
);

-- Table: ETHNICITY
CREATE TABLE ETHNICITY (
                           ETH_ID SERIAL PRIMARY KEY,
                           ETH_TRIBE_NAME VARCHAR(100) NOT NULL
);

-- Table: RELIGION
CREATE TABLE RELIGION (
                          REL_ID SERIAL PRIMARY KEY,
                          REL_NAME VARCHAR(100) NOT NULL
);

-- Table: SOCIO_ECONOMIC_STATUS
CREATE TABLE SOCIO_ECONOMIC_STATUS (
                                       SOEC_ID SERIAL PRIMARY KEY,
                                       SOEC_STATUS VARCHAR(100) NOT NULL CHECK (
                                           SOEC_STATUS IN ('NHTS 4Ps', 'NHTS Non-4Ps', 'Non-NHTS')
                                           ),
                                       SOEC_NUMBER VARCHAR(50),
                                       CONSTRAINT chk_socio_status CHECK (
                                           (SOEC_STATUS IN ('NHTS 4Ps', 'NHTS Non-4Ps') AND SOEC_NUMBER IS NOT NULL)
                                               OR
                                           (SOEC_STATUS = 'Non-NHTS')
                                           )
);


CREATE TYPE blood_type_enum AS ENUM(
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-','None'
    );


CREATE TYPE civil_status_type AS ENUM(
    'Single', 'Married', 'Widowed', 'Separated'
    );

-- Table: WATER_SOURCE
CREATE TABLE WATER_SOURCE(
                             WATER_ID SERIAL PRIMARY KEY,
                             WATER_SOURCE_NAME VARCHAR(50) NOT NULL
);

-- Table: WATER_SOURCE
CREATE TABLE TOILET_TYPE(
                            TOIL_ID SERIAL PRIMARY KEY,
                            TOIL_TYPE_NAME VARCHAR(50) NOT NULL
);

-- Table: RELATIONSHIP_TYPE
CREATE TABLE RELATIONSHIP_TYPE (
                                   RTH_ID SERIAL PRIMARY KEY,
                                   RTH_RELATIONSHIP_NAME VARCHAR(100)
);

CREATE TYPE house_ownership_status as ENUM(
    'Owned', 'Rented', 'Leased', 'Informal Settler'
    );

-- Table: HOUSEHOLD_INFO
CREATE TABLE HOUSEHOLD_INFO (
                                HH_ID SERIAL PRIMARY KEY,
                                HH_HOUSE_NUMBER VARCHAR(50) UNIQUE NOT NULL,
                                HH_ADDRESS TEXT,
                                HH_OWNERSHIP_STATUS house_ownership_status,
                                HH_HOME_GOOGLE_LINK TEXT,
                                HH_INTERVIEWER_NAME VARCHAR(100),
                                HH_REVIEWER_NAME VARCHAR(100),
                                HH_DATE_VISIT DATE NOT NULL,
                                HH_DATE_ENCODED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                HH_LAST_UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                HH_IS_DELETED BOOLEAN DEFAULT FALSE,
                                HH_IS_PENDING_DELETE BOOLEAN DEFAULT FALSE,
                                HH_DELETE_REQ_REASON TEXT,
                                WATER_ID INT NOT NULL,
                                TOILET_ID INT NOT NULL,
                                SITIO_ID INT NOT NULL,
                                ENCODED_BY_SYS_ID INT NOT NULL,
                                LAST_UPDATED_BY_SYS_ID INT NOT NULL,
                                CONSTRAINT fk_water_source FOREIGN KEY (WATER_ID) REFERENCES WATER_SOURCE(WATER_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
                                CONSTRAINT fk_toilet_type FOREIGN KEY (TOILET_ID) REFERENCES TOILET_TYPE(TOIL_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
                                CONSTRAINT fk_sitio FOREIGN KEY (SITIO_ID) REFERENCES SITIO(SITIO_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
                                CONSTRAINT fk_encoded_by FOREIGN KEY (ENCODED_BY_SYS_ID) REFERENCES SYSTEM_ACCOUNT(SYS_USER_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
                                CONSTRAINT fk_last_updated_by FOREIGN KEY (LAST_UPDATED_BY_SYS_ID) REFERENCES SYSTEM_ACCOUNT(SYS_USER_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
                                CONSTRAINT chk_pending_delete CHECK (
                                    (HH_IS_PENDING_DELETE = TRUE AND HH_DELETE_REQ_REASON IS NOT NULL) OR
                                    (HH_IS_PENDING_DELETE = FALSE AND HH_DELETE_REQ_REASON IS NULL)
                                    )
);




-- Table: EDUCATIONAL_ATTAINMENT
CREATE TABLE EDUCATIONAL_ATTAINMENT (
                                        EDAT_ID SERIAL PRIMARY KEY,
                                        EDAT_LEVEL VARCHAR(100)
);

-- Table: EDUCATION_STATUS
CREATE TABLE EDUCATION_STATUS (
                                  EDU_ID SERIAL PRIMARY KEY,
                                  EDU_IS_CURRENTLY_STUDENT BOOLEAN,
                                  EDU_INSTITUTION_NAME VARCHAR(255),
                                  EDAT_ID INT REFERENCES EDUCATIONAL_ATTAINMENT(EDAT_ID)
);

-- Table: PHILHEALTH_CATEGORY
CREATE TABLE PHILHEALTH_CATEGORY (
                                     PC_ID SERIAL PRIMARY KEY,
                                     PC_CATEGORY_NAME VARCHAR(100) NOT NULL
);

-- Table: PHILHEALTH
CREATE TABLE PHILHEALTH (
                            PHEA_ID SERIAL PRIMARY KEY,
                            PHEA_ID_NUMBER VARCHAR(50),
                            PHEA_MEMBERSHIP_TYPE VARCHAR(50) CHECK(
                                PHEA_MEMBERSHIP_TYPE IN (
                                                         'None',
                                                         'Member',
                                                         'Dependent'
                                    )
                                ),
                            PC_ID INT NOT NULL REFERENCES PHILHEALTH_CATEGORY(PC_ID)
);

CREATE SEQUENCE SYS_CTZ_ID_SEQ START 1001;


-- Table: CONTACT
CREATE TABLE CONTACT (
                         CON_ID SERIAL PRIMARY KEY,
                         CON_PHONE VARCHAR(20),
                         CON_EMAIL VARCHAR(100)

);




-- Table: CITIZEN
CREATE TABLE CITIZEN (
                         CTZ_ID SERIAL PRIMARY KEY,
                         CTZ_UUID INT UNIQUE DEFAULT NEXTVAL('SYS_CTZ_ID_SEQ'),
                         CTZ_FIRST_NAME VARCHAR(100) NOT NULL,
                         CTZ_MIDDLE_NAME VARCHAR(100),
                         CTZ_LAST_NAME VARCHAR(100) NOT NULL,
                         CTZ_SUFFIX VARCHAR(10),
                         CTZ_DATE_OF_BIRTH DATE NOT NULL,
                         CTZ_SEX CHAR(1) NOT NULL CHECK (CTZ_SEX IN ('M', 'F')),
                         CTZ_CIVIL_STATUS civil_status_type NOT NULL,
                         CTZ_BLOOD_TYPE blood_type_enum,
                         CTZ_IS_ALIVE BOOLEAN DEFAULT TRUE,
                         CTZ_DATE_OF_DEATH DATE,
                         CTZ_REASON_OF_DEATH TEXT,
                         CTZ_IS_REGISTERED_VOTER BOOLEAN DEFAULT FALSE,
                         CTZ_IS_IP BOOLEAN DEFAULT FALSE,
                         CTZ_PLACE_OF_BIRTH TEXT NOT NULL,
                         CTZ_DATE_ENCODED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                         CTZ_LAST_UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                         CTZ_IS_DELETED BOOLEAN DEFAULT FALSE,
                         CTZ_IS_PENDING_DELETE BOOLEAN DEFAULT FALSE,
                         CTZ_DELETE_REQ_REASON TEXT,

                         EDU_ID INT,
                         SOEC_ID INT NOT NULL,
                         PHEA_ID INT,
                         REL_ID INT,
                         ETH_ID INT,
                         CLAH_ID INT,
                         RTH_ID INT NOT NULL,
                         HH_ID INT NOT NULL,
                         SITIO_ID INT NOT NULL,
                         ENCODED_BY_SYS_ID INT NOT NULL,
                         LAST_UPDATED_BY_SYS_ID INT NOT NULL,
                         CON_ID INT,  -- Added contact reference here

                         CONSTRAINT fk_encoded_by FOREIGN KEY (ENCODED_BY_SYS_ID) REFERENCES SYSTEM_ACCOUNT(SYS_USER_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
                         CONSTRAINT fk_last_updated_by FOREIGN KEY (LAST_UPDATED_BY_SYS_ID) REFERENCES SYSTEM_ACCOUNT(SYS_USER_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
                         CONSTRAINT fk_edu_id FOREIGN KEY (EDU_ID) REFERENCES EDUCATION_STATUS(EDU_ID) ON UPDATE CASCADE ON DELETE CASCADE,
                         CONSTRAINT fk_soec_id FOREIGN KEY (SOEC_ID) REFERENCES SOCIO_ECONOMIC_STATUS(SOEC_ID) ON UPDATE CASCADE ON DELETE CASCADE,
                         CONSTRAINT fk_phea_id FOREIGN KEY (PHEA_ID) REFERENCES PHILHEALTH(PHEA_ID) ON UPDATE CASCADE ON DELETE CASCADE,
                         CONSTRAINT fk_rel_id FOREIGN KEY (REL_ID) REFERENCES RELIGION(REL_ID) ON UPDATE CASCADE ON DELETE CASCADE,
                         CONSTRAINT fk_eth_id FOREIGN KEY (ETH_ID) REFERENCES ETHNICITY(ETH_ID) ON UPDATE CASCADE ON DELETE CASCADE,
                         CONSTRAINT fk_clah_id FOREIGN KEY (CLAH_ID) REFERENCES CLASSIFICATION_HEALTH_RISK(CLAH_ID) ON UPDATE CASCADE ON DELETE SET NULL,
                         CONSTRAINT fk_rth_id FOREIGN KEY (RTH_ID) REFERENCES RELATIONSHIP_TYPE(RTH_ID) ON UPDATE CASCADE ON DELETE CASCADE,
                         CONSTRAINT fk_hh_id FOREIGN KEY (HH_ID) REFERENCES HOUSEHOLD_INFO(HH_ID) ON UPDATE CASCADE ON DELETE CASCADE,
                         CONSTRAINT fk_sitio_id FOREIGN KEY (SITIO_ID) REFERENCES SITIO(SITIO_ID) ON UPDATE CASCADE ON DELETE CASCADE,
                         CONSTRAINT fk_con_id FOREIGN KEY (CON_ID) REFERENCES CONTACT(CON_ID) ON UPDATE CASCADE ON DELETE SET NULL,

                         CONSTRAINT chk_ethnicity CHECK (
                             (CTZ_IS_IP = TRUE AND ETH_ID IS NOT NULL) OR
                             (CTZ_IS_IP = FALSE AND ETH_ID IS NULL)
                             ),
                         CONSTRAINT chk_pending_delete CHECK (
                             (CTZ_IS_PENDING_DELETE = FALSE) OR
                             (CTZ_IS_PENDING_DELETE = TRUE AND CTZ_DELETE_REQ_REASON IS NOT NULL)
                             ),
                         CONSTRAINT chk_is_alive CHECK (
                             (CTZ_IS_ALIVE = TRUE) OR
                             (CTZ_IS_ALIVE = FALSE AND CTZ_DATE_OF_DEATH IS NOT NULL AND CTZ_REASON_OF_DEATH IS NOT NULL)
                             )
);


-- Table: INFRASTRUCTURE_TYPE
CREATE TABLE INFRASTRUCTURE_TYPE (
                                     INFT_ID SERIAL PRIMARY KEY,
                                     INFT_TYPE_NAME VARCHAR(100) NOT NULL
);

-- Table: INFRASTRUCTURE_OWNER
CREATE TABLE INFRASTRUCTURE_OWNER (
                                      INFO_ID SERIAL PRIMARY KEY,
                                      INFO_LNAME VARCHAR(100) NOT NULL,
                                      INFO_FNAME VARCHAR(100) NOT NULL,
                                      INFO_MNAME VARCHAR(100)
);


-- Table: INFRASTRUCTURE
CREATE TABLE INFRASTRUCTURE (
                                INF_ID SERIAL PRIMARY KEY,
                                INF_NAME VARCHAR(100) NOT NULL,
                                INF_ACCESS_TYPE VARCHAR(10) NOT NULL CHECK ( INF_ACCESS_TYPE IN ('Public', 'Private')),
                                INF_DESCRIPTION TEXT,
                                INF_ADDRESS_DESCRIPTION TEXT,
                                INF_DATE_ENCODED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                INF_LAST_UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                INF_IS_DELETED BOOLEAN DEFAULT FALSE,
                                INF_IS_PENDING_DELETE BOOLEAN DEFAULT FALSE,
                                INF_DELETE_REQ_REASON TEXT,
                                INFT_ID INT NOT NULL REFERENCES INFRASTRUCTURE_TYPE(INFT_ID),
                                INFO_ID INT REFERENCES INFRASTRUCTURE_OWNER(INFO_ID) ON DELETE CASCADE ON UPDATE CASCADE,
                                SITIO_ID INT NOT NULL REFERENCES SITIO(SITIO_ID),
                                ENCODED_BY_SYS_ID INT NOT NULL,
                                LAST_UPDATED_BY_SYS_ID INT NOT NULL,

                                CONSTRAINT fk_encoded_by FOREIGN KEY (ENCODED_BY_SYS_ID) REFERENCES SYSTEM_ACCOUNT(SYS_USER_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
                                CONSTRAINT fk_last_updated_by FOREIGN KEY (LAST_UPDATED_BY_SYS_ID) REFERENCES SYSTEM_ACCOUNT(SYS_USER_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
                                CONSTRAINT chk_access_type CHECK (
                                    (INF_ACCESS_TYPE = 'Private' AND INFO_ID IS NOT NULL) OR
                                    (INF_ACCESS_TYPE = 'Public' AND INFO_ID IS NULL)
                                    ),
                                CONSTRAINT chk_pending_delete CHECK (
                                    (INF_IS_PENDING_DELETE = FALSE) OR
                                    (INF_IS_PENDING_DELETE = TRUE AND INF_DELETE_REQ_REASON IS NOT NULL)
                                    )
);


-- Table: FAMILY_PLANNING_METHOD
CREATE TABLE FAMILY_PLANNING_METHOD (
                                        FPM_ID SERIAL PRIMARY KEY,
                                        FPM_METHOD VARCHAR(100)
);

-- Table: FPM_STATUS
CREATE TABLE FPM_STATUS (
                            FPMS_ID SERIAL PRIMARY KEY,
                            FPMS_STATUS_NAME VARCHAR(100)
);

-- Table: FAMILY_PLANNING
CREATE TABLE FAMILY_PLANNING (
                                 FP_ID SERIAL PRIMARY KEY,
                                 FP_START_DATE DATE,
                                 FP_END_DATE DATE,
                                 CTZ_ID INT NOT NULL REFERENCES CITIZEN(CTZ_ID),
                                 FPMS_STATUS INT NOT NULL REFERENCES FPM_STATUS(FPMS_ID),
                                 FPM_METHOD INT NOT NULL REFERENCES FAMILY_PLANNING_METHOD(FPM_ID)
);


CREATE TABLE BUSINESS_TYPE(
                              BST_ID INT PRIMARY KEY,
                              BST_TYPE_NAME VARCHAR(100) NOT NULL
);

CREATE TYPE business_status_enum AS ENUM(
    'Active',
    'Inactive',
    'Closed',
    'Suspended'
    );

--
-- Table: BUSINESS_INFO
CREATE TABLE BUSINESS_INFO (
                               BS_ID SERIAL PRIMARY KEY,
                               BS_NAME VARCHAR(100) NOT NULL,
                               BS_DESCRIPTION TEXT,
                               BS_STATUS business_status_enum NOT NULL,
                               BS_IS_DTI BOOLEAN NOT NULL,
                               BS_ADDRESS TEXT NOT NULL,
                               BS_DATE_ENCODED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                               BS_LAST_UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                               BS_IS_DELETED BOOLEAN DEFAULT FALSE,
                               BS_IS_PENDING_DELETE BOOLEAN DEFAULT FALSE,
                               BS_DELETE_REQ_REASON TEXT,
                               BS_FNAME VARCHAR(50) NOT NULL,
                               BS_LNAME VARCHAR(50) NOT NULL,
                               BST_ID INT NOT NULL REFERENCES BUSINESS_TYPE(BST_ID),
                               SITIO_ID INT NOT NULL REFERENCES SITIO(SITIO_ID) ON DELETE CASCADE ON UPDATE CASCADE,
                               ENCODED_BY_SYS_ID INT NOT NULL,
                               LAST_UPDATED_BY_SYS_ID INT NOT NULL,

                               CONSTRAINT fk_encoded_by FOREIGN KEY (ENCODED_BY_SYS_ID) REFERENCES SYSTEM_ACCOUNT(SYS_USER_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
                               CONSTRAINT fk_last_updated_by FOREIGN KEY (LAST_UPDATED_BY_SYS_ID) REFERENCES SYSTEM_ACCOUNT(SYS_USER_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
                               CONSTRAINT chk_pending_delete CHECK (
                                   (BS_IS_PENDING_DELETE = FALSE) OR
                                   (BS_IS_PENDING_DELETE = TRUE AND BS_DELETE_REQ_REASON IS NOT NULL)
                                   )
);

-- Table: EMPLOYMENT_STATUS
CREATE TABLE EMPLOYMENT_STATUS (
                                   ES_ID SERIAL PRIMARY KEY,
                                   ES_STATUS_NAME VARCHAR(100)
);

-- Table: EMPLOYMENT
CREATE TABLE EMPLOYMENT (
                            EMP_ID SERIAL PRIMARY KEY,
                            EMP_OCCUPATION VARCHAR(100),
                            EMP_IS_GOV_WORKER BOOLEAN DEFAULT FALSE,
                            ES_ID INT REFERENCES EMPLOYMENT_STATUS(ES_ID),
                            CTZ_ID INT NOT NULL REFERENCES CITIZEN(CTZ_ID)
);

-- Table: TRANSACTION_TYPE
CREATE TABLE TRANSACTION_TYPE (
                                  TT_ID SERIAL PRIMARY KEY,
                                  TT_TYPE_NAME VARCHAR(100) NOT NULL
);

CREATE TYPE transaction_status_enum AS ENUM(
    'Pending',
    'Approved',
    'Declined'
    );

-- Table: TRANSACTION_LOG
CREATE TABLE TRANSACTION_LOG (
                                 TL_ID SERIAL PRIMARY KEY,
                                 TL_DATE_REQUESTED DATE DEFAULT CURRENT_DATE,
                                 TL_PURPOSE VARCHAR(150) NOT NULL,
                                 TL_STATUS transaction_status_enum,
                                 TL_FNAME VARCHAR(50) NOT NULL,
                                 TL_LNAME VARCHAR(50) NOT NULL,
                                 TL_DATE_ENCODED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                 TL_LAST_UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                 TL_IS_DELETED BOOLEAN DEFAULT FALSE,
                                 TL_IS_PENDING_DELETE BOOLEAN DEFAULT FALSE,
                                 TL_DELETE_REQ_REASON TEXT,
                                 TT_ID INT NOT NULL REFERENCES TRANSACTION_TYPE(TT_ID),
                                 ENCODED_BY_SYS_ID INT NOT NULL,
                                 LAST_UPDATED_BY_SYS_ID INT NOT NULL,

                                 CONSTRAINT fk_encoded_by FOREIGN KEY (ENCODED_BY_SYS_ID) REFERENCES SYSTEM_ACCOUNT(SYS_USER_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
                                 CONSTRAINT fk_last_updated_by FOREIGN KEY (LAST_UPDATED_BY_SYS_ID) REFERENCES SYSTEM_ACCOUNT(SYS_USER_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
                                 CONSTRAINT chk_pending_delete CHECK (
                                     (TL_IS_PENDING_DELETE = FALSE) OR
                                     (TL_IS_PENDING_DELETE = TRUE AND TL_DELETE_REQ_REASON IS NOT NULL)
                                     )
);

-- Table: MEDICAL_HISTORY_TYPE
CREATE TABLE MEDICAL_HISTORY_TYPE(
                                     MHT_ID SERIAL PRIMARY KEY,
                                     MHT_TYPE_NAME VARCHAR(100) NOT NULL
);

-- Table: MEDICAL_HISTORY
CREATE TABLE MEDICAL_HISTORY (
                                 MH_ID SERIAL PRIMARY KEY,
                                 MH_DESCRIPTION VARCHAR(100) NOT NULL,
                                 MH_DATE_DIAGNOSED DATE,
                                 MH_DATE_ENCODED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                 MH_LAST_UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                 MH_IS_DELETED BOOLEAN DEFAULT FALSE,
                                 MH_IS_PENDING_DELETE BOOLEAN DEFAULT FALSE,
                                 MH_DELETE_REQ_REASON TEXT,
                                 MHT_ID INT NOT NULL REFERENCES MEDICAL_HISTORY_TYPE(MHT_ID),
                                 CTZ_ID INT NOT NULL REFERENCES CITIZEN(CTZ_ID),
                                 ENCODED_BY_SYS_ID INT NOT NULL,
                                 LAST_UPDATED_BY_SYS_ID INT NOT NULL,

                                 CONSTRAINT fk_encoded_by FOREIGN KEY (ENCODED_BY_SYS_ID) REFERENCES SYSTEM_ACCOUNT(SYS_USER_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
                                 CONSTRAINT fk_last_updated_by FOREIGN KEY (LAST_UPDATED_BY_SYS_ID) REFERENCES SYSTEM_ACCOUNT(SYS_USER_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
                                 CONSTRAINT chk_pending_delete CHECK (
                                     (MH_IS_PENDING_DELETE = FALSE) OR
                                     (MH_IS_PENDING_DELETE = TRUE AND MH_DELETE_REQ_REASON IS NOT NULL)
                                     )
);



-- Table: HISTORY_TYPE
CREATE TABLE HISTORY_TYPE (
                              HIST_ID SERIAL PRIMARY KEY,
                              HIST_TYPE_NAME VARCHAR(100) NOT NULL
);

-- Table: CITIZEN_HISTORY
CREATE TABLE CITIZEN_HISTORY (
                                 CIHI_ID SERIAL PRIMARY KEY,
                                 CIHI_DESCRIPTION VARCHAR(100) NOT NULL,
                                 CIHI_DATE_ENCODED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                 CIHI_LAST_UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                 CIHI_IS_DELETED BOOLEAN DEFAULT FALSE,
                                 CIHI_IS_PENDING_DELETE BOOLEAN DEFAULT FALSE,
                                 CIHI_DELETE_REQ_REASON TEXT,
                                 HIST_ID INT NOT NULL REFERENCES HISTORY_TYPE(HIST_ID),
                                 CTZ_ID INT NOT NULL REFERENCES CITIZEN(CTZ_ID),
                                 ENCODED_BY_SYS_ID INT NOT NULL,
                                 LAST_UPDATED_BY_SYS_ID INT NOT NULL,

                                 CONSTRAINT fk_encoded_by FOREIGN KEY (ENCODED_BY_SYS_ID) REFERENCES SYSTEM_ACCOUNT(SYS_USER_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
                                 CONSTRAINT fk_last_updated_by FOREIGN KEY (LAST_UPDATED_BY_SYS_ID) REFERENCES SYSTEM_ACCOUNT(SYS_USER_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
                                 CONSTRAINT chk_pending_delete CHECK (
                                     (CIHI_IS_PENDING_DELETE = FALSE) OR
                                     (CIHI_IS_PENDING_DELETE = TRUE AND CIHI_DELETE_REQ_REASON IS NOT NULL)
                                     )
);

CREATE TABLE COMPLAINANT(
                            COMP_ID SERIAL PRIMARY KEY,
                            COMP_FNAME VARCHAR(50) NOT NULL,
                            COMP_LNAME VARCHAR(50) NOT NULL,
                            COMP_MNAME VARCHAR(50)
);

-- Table: SETTLEMENT_LOG
CREATE TABLE SETTLEMENT_LOG(
                               SETT_ID SERIAL PRIMARY KEY,
                               SETT_COMPLAINT_DESCRIPTION TEXT NOT NULL,
                               SETT_SETTLEMENT_DESCRIPTION TEXT NOT NULL,
                               SETT_DATE_OF_SETTLEMENT DATE NOT NULL,
                               SETT_DATE_ENCODED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                               SETT_LAST_UPDATED TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                               SETT_IS_DELETED BOOLEAN DEFAULT FALSE,
                               SETT_IS_PENDING_DELETE BOOLEAN DEFAULT FALSE,
                               SETT_DELETE_REQ_REASON TEXT,
                               COMP_ID INT NOT NULL REFERENCES COMPLAINANT(COMP_ID),
                               CIHI_ID INT NOT NULL REFERENCES CITIZEN_HISTORY(CIHI_ID),
                               ENCODED_BY_SYS_ID INT NOT NULL,
                               LAST_UPDATED_BY_SYS_ID INT NOT NULL,
                               CONSTRAINT fk_encoded_by FOREIGN KEY (ENCODED_BY_SYS_ID) REFERENCES SYSTEM_ACCOUNT(SYS_USER_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
                               CONSTRAINT fk_last_updated_by FOREIGN KEY (LAST_UPDATED_BY_SYS_ID) REFERENCES SYSTEM_ACCOUNT(SYS_USER_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
                               CONSTRAINT chk_pending_delete CHECK (
                                   (SETT_IS_PENDING_DELETE = FALSE) OR
                                   (SETT_IS_PENDING_DELETE = TRUE AND SETT_DELETE_REQ_REASON IS NOT NULL)
                                   )
);

--TRIGGER FUNCTIONS

--AUTO UPDATE LAST UPDATED

CREATE OR REPLACE FUNCTION update_last_updated_citizen()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.CTZ_LAST_UPDATED = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_citizen_last_updated
    BEFORE UPDATE ON CITIZEN
    FOR EACH ROW
EXECUTE FUNCTION update_last_updated_citizen();



CREATE OR REPLACE FUNCTION update_last_updated_household()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.HH_LAST_UPDATED = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_household_last_updated
    BEFORE UPDATE ON HOUSEHOLD_INFO
    FOR EACH ROW
EXECUTE FUNCTION update_last_updated_household();



CREATE OR REPLACE FUNCTION update_last_updated_infrastructure()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.INF_LAST_UPDATED = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_infrastructure_last_updated
    BEFORE UPDATE ON INFRASTRUCTURE
    FOR EACH ROW
EXECUTE FUNCTION update_last_updated_infrastructure();



CREATE OR REPLACE FUNCTION update_last_updated_business()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.BS_LAST_UPDATED = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_business_last_updated
    BEFORE UPDATE ON BUSINESS_INFO
    FOR EACH ROW
EXECUTE FUNCTION update_last_updated_business();


CREATE OR REPLACE FUNCTION update_last_updated_transaction()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.TL_LAST_UPDATED = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_transaction_last_updated
    BEFORE UPDATE ON TRANSACTION_LOG
    FOR EACH ROW
EXECUTE FUNCTION update_last_updated_transaction();



CREATE OR REPLACE FUNCTION update_last_updated_medical()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.MH_LAST_UPDATED = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_medical_last_updated
    BEFORE UPDATE ON MEDICAL_HISTORY
    FOR EACH ROW
EXECUTE FUNCTION update_last_updated_medical();



CREATE OR REPLACE FUNCTION update_last_updated_citizen_history()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.CIHI_LAST_UPDATED = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_citizen_history_last_updated
    BEFORE UPDATE ON CITIZEN_HISTORY
    FOR EACH ROW
EXECUTE FUNCTION update_last_updated_citizen_history();



CREATE OR REPLACE FUNCTION update_last_updated_settlement()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.SETT_LAST_UPDATED = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_settlement_last_updated
    BEFORE UPDATE ON MEDICAL_HISTORY
    FOR EACH ROW
EXECUTE FUNCTION update_last_updated_settlement();

SELECT sitio_name, COUNT(HH_ID) AS total_households
FROM HOUSEHOLD_INFO hh
         Left JOIN sitio s ON hh.sitio_id = s.sitio_id
GROUP BY sitio_name
ORDER BY total_households DESC
LIMIT 1;



--VIEWS

-- this view gets the age from the dob, and assigns a corresponding classification
CREATE OR REPLACE VIEW citizen_with_age_classification AS
SELECT
    CTZ_ID,
    CTZ_FIRST_NAME,
    CTZ_MIDDLE_NAME,
    CTZ_LAST_NAME,
    ctz_date_of_birth,
    ctz_is_alive,
    CTZ_IS_DELETED,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, ctz_date_of_birth)) AS age,
    CASE
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, ctz_date_of_birth)) BETWEEN 0 AND 2 THEN 'Infant'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, ctz_date_of_birth)) BETWEEN 3 AND 12 THEN 'Child'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, ctz_date_of_birth)) BETWEEN 13 AND 17 THEN 'Teen'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, ctz_date_of_birth)) BETWEEN 18 AND 24 THEN 'Young Adult'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, ctz_date_of_birth)) BETWEEN 25 AND 39 THEN 'Adult'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, ctz_date_of_birth)) BETWEEN 40 AND 59 THEN 'Middle Aged'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, ctz_date_of_birth)) >= 60 THEN 'Senior'
        ELSE 'Unknown'
        END AS age_classification
FROM
    citizen
WHERE
    ctz_is_alive = TRUE;


-- ONLY FOR CTIZEN
CREATE OR REPLACE FUNCTION log_entity_activity()
    RETURNS TRIGGER AS $$
DECLARE
    v_entity_id INT;
BEGIN

    IF TG_OP = 'INSERT' THEN
        v_entity_id := NEW.CTZ_ID;
    ELSIF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        v_entity_id := OLD.CTZ_ID;
    END IF;

    INSERT INTO SYSTEM_ACTIVITY_LOG (
        ACT_ACTION_TYPE,
        ACT_TABLE_NAME,
        ACT_ENTITY_ID,
        SYS_ID,
        ACT_DESCRIPTION
    )
    VALUES (
               TG_OP::action_type_enum,
               TG_TABLE_NAME,
               v_entity_id,
               current_setting('app.current_user_id')::INT,
               CONCAT('Action ', TG_OP, ' on ', TG_TABLE_NAME, ' ID = ', v_entity_id)
           );

    RETURN CASE
               WHEN TG_OP = 'DELETE' THEN OLD
               ELSE NEW
        END;
END;
$$ LANGUAGE plpgsql;

--TEMPORARY ONLY, NEEDS TO BE DELETED LATER
SET app.current_user_id = '1';

--INSERTS


-- SUPER ADMIN
INSERT INTO SYSTEM_ACCOUNT(SYS_PASSWORD, SYS_FNAME, SYS_MNAME, SYS_LNAME, SYS_ROLE)
VALUES
    (000001, 'Ian','Neko', 'Majica','Super Admin');

INSERT INTO WATER_SOURCE(WATER_SOURCE_NAME)
VALUES
    ('Level 1 - Point Source'),
    ('Level 2 - Communal Faucet'),
    ('Level 3 - Individual Connection'),
    ('Others');

INSERT INTO TOILET_TYPE (TOIL_TYPE_NAME)
VALUES
    ('A - Pour/flush type connected to septic tank'),
    ('B - Pour/flush toilet connected to Sewerage System '),
    ('C - Ventilated Pit (VIP) latrine'),
    ('D - Water-sealed toilet'),
    ('E - Overhung latrine'),
    ('F - Open pit latrine'),
    ('E - G - Without toilet');

INSERT INTO SITIO(SITIO_NAME)
VALUES
    ('Cadulang 1'),
    ('Cadulang 2'),
    ('Cambiohan'),
    ('Chocolate Hills'),
    ('Hawaiian 1'),
    ('Hawaiian 2'),
    ('Ikaseg'),
    ('Ibabao'),
    ('Kalubihan'),
    ('Kaisid'),
    ('Kolo'),
    ('Limogmog'),
    ('Likoan'),
    ('Marbeach'),
    ('Mahayahay'),
    ('Masiwa'),
    ('Matab-ang'),
    ('Osflor'),
    ('Marigondon Proper'),
    ('San Carlos'),
    ('St. Joseph'),
    ('Sto. Kristo'),
    ('Sto. Niño'),
    ('Tabay Mabao'),
    ('Villa Verna'),
    ('Whitefox'),
    ('Ylaya'),
    ('Ylacir');

INSERT INTO SYSTEM_ACCOUNT (
    SYS_PASSWORD,
    SYS_FNAME,
    SYS_MNAME,
    SYS_LNAME,
    SYS_ROLE
) VALUES
      -- Sample super Admin (no department/permissions needed)
      ('000001', 'Juan', 'Dela', 'Cruz', 'Super Admin'),

      -- Regular Admin (requires department and permissions)
      ('000002', 'Maria', 'Santos', 'Reyes', 'Admin');




INSERT INTO CLASSIFICATION_HEALTH_RISK (CLAH_CLASSIFICATION_NAME)
VALUES
    ('None'),
    ('Pregnant'),
    ('Adolescent Pregnant'),
    ('Postpartum'),
    ('Infant'),
    ('Under 5 Years Old'),
    ('Person With Disability');



INSERT INTO RELATIONSHIP_TYPE (RTH_RELATIONSHIP_NAME)
VALUES
    ('Head'),
    ('Spouse'),
    ('Son'),
    ('Daughter'),
    ('Other Relative');

INSERT INTO RELIGION (REL_ID, REL_NAME) VALUES
                                            (1, 'None'),
                                            (2, 'Roman Catholic'),
                                            (3, 'Christian'),
                                            (4, 'Iglesia ni Cristo'),
                                            (5, 'Born Again Christian'),
                                            (6, 'Hinduism'),
                                            (7, 'Church of God'),
                                            (8, 'Jehovah''s Witness'),
                                            (9, 'Mormon'),
                                            (10, 'Islam'),
                                            (11, 'Others');


INSERT INTO SOCIO_ECONOMIC_STATUS (SOEC_STATUS, SOEC_NUMBER)
VALUES
    ('NHTS 4Ps', '123456'),
    ('NHTS Non-4Ps', '654321'),
    ('Non-NHTS', 'N/A');

--sample household
INSERT INTO HOUSEHOLD_INFO (
    HH_HOUSE_NUMBER,
    HH_ADDRESS,
    HH_OWNERSHIP_STATUS,
    HH_HOME_GOOGLE_LINK,
    HH_INTERVIEWER_NAME,
    HH_REVIEWER_NAME,
    HH_DATE_VISIT,
    WATER_ID,
    TOILET_ID,
    SITIO_ID,
    ENCODED_BY_SYS_ID,
    LAST_UPDATED_BY_SYS_ID
) VALUES (
             'HM-2023-001',
             '123 Purok Santan, Barangay Marigondon',
             'Owned',
             'https://www.google.com/maps/place/Shell+Robinsons+Mobility+Station+-+Galleria+Cebu+City/@10.3024076,123.9108788,19.5z/data=!4m6!3m5!1s0x33a999f29f761867:0x51e0d3123523c12a!8m2!3d10.3025851!4d123.9110295!16s%2Fg%2F11rrs0pzvl?authuser=0&entry=ttu&g_ep=EgoyMDI1MDQzMC4xIKXMDSoASAFQAw%3D%3D',
             'Juan Dela Cruz',
             'Maria Reyes',
             CURRENT_DATE,
             (SELECT WATER_ID FROM WATER_SOURCE WHERE WATER_SOURCE_NAME = 'Level 3 - Individual Connection'),
             (SELECT TOIL_ID FROM TOILET_TYPE WHERE TOIL_TYPE_NAME = 'A - Pour/flush type connected to septic tank'),
             (SELECT SITIO_ID FROM SITIO WHERE SITIO_NAME = 'Ylaya'),1001,1001
         );


-- EDUCATION
INSERT INTO EDUCATIONAL_ATTAINMENT(EDAT_ID, EDAT_LEVEL)
VALUES
    (1, 'No Formal Education'),
    (2, 'Kindergarten'),
    (3, 'Elementary Undergraduate'),
    (4, 'Elementary Graduate'),
    (5, 'Junior High School Undergraduate'),
    (6, 'Junior High School Graduate'),
    (7, 'Senior High School Undergraduate'),
    (8, 'Senior High School Graduate'),
    (9, 'Vocational / Technical Graduate'),
    (10, 'College Undergraduate'),
    (11, 'College Graduate'),
    (12, 'Postgraduate');


--inserts an education status and returns its id for reference in citizen
INSERT INTO EDUCATION_STATUS(EDU_IS_CURRENTLY_STUDENT, EDU_INSTITUTION_NAME, EDAT_ID)
VALUES (
           FALSE,
           'Cebu Technological University',
           11
       )RETURNING EDU_ID;



--sample citizen (household head)
INSERT INTO CITIZEN (
    CTZ_FIRST_NAME,
    CTZ_MIDDLE_NAME,
    CTZ_LAST_NAME,
    CTZ_DATE_OF_BIRTH,
    CTZ_SEX,
    CTZ_CIVIL_STATUS,
    CTZ_BLOOD_TYPE,
    CTZ_PLACE_OF_BIRTH,
    ENCODED_BY_SYS_ID,
    LAST_UPDATED_BY_SYS_ID,
    EDU_ID,
    SOEC_ID,
    REL_ID,
    CLAH_ID,
    RTH_ID,
    HH_ID,
    SITIO_ID
) VALUES (
             'Roberto',
             'Santos',
             'Gonzales',
             '1980-05-15',
             'M',
             'Married',
             'O+',
             'Cebu City',
             (SELECT SYS_USER_ID FROM SYSTEM_ACCOUNT WHERE SYS_USER_ID = 1001),
             (SELECT SYS_USER_ID FROM SYSTEM_ACCOUNT WHERE SYS_USER_ID = 1001),
             1,
             (SELECT SOEC_ID FROM SOCIO_ECONOMIC_STATUS WHERE SOEC_STATUS = 'NHTS 4Ps'),
             (SELECT REL_ID FROM RELIGION WHERE REL_NAME = 'Roman Catholic'),
             3,
             (SELECT RTH_ID FROM RELATIONSHIP_TYPE WHERE RTH_RELATIONSHIP_NAME = 'Head'),
             (SELECT HH_ID FROM HOUSEHOLD_INFO WHERE HH_HOUSE_NUMBER = 'HM-2023-001'),
             (SELECT SITIO_ID FROM SITIO WHERE SITIO_NAME = 'Marigondon Proper')
         );



-- INFRASTRUCTURE
INSERT INTO INFRASTRUCTURE_TYPE (INFT_TYPE_NAME)
VALUES
    ('Barangay Hall'),
    ('Health Center'),
    ('Daycare Center'),
    ('Basketball Court');

INSERT INTO INFRASTRUCTURE_OWNER (INFO_LNAME, INFO_FNAME, INFO_MNAME)
VALUES
    ('Tan', 'Michael', 'C'),
    ('Lim', 'Angela', 'B');

INSERT INTO INFRASTRUCTURE (
    INF_NAME,
    INF_ACCESS_TYPE,
    INF_DESCRIPTION,
    INF_ADDRESS_DESCRIPTION,
    INFO_ID,
    INFT_ID,
    SITIO_ID,
    ENCODED_BY_SYS_ID,
    LAST_UPDATED_BY_SYS_ID
) VALUES
      ('Marigondon Barangay Hall', 'Public', 'Main government building', 'Near the highway', Null,
       (SELECT INFT_ID FROM INFRASTRUCTURE_TYPE WHERE INFT_TYPE_NAME = 'Barangay Hall'),
       (SELECT SITIO_ID FROM SITIO WHERE SITIO_NAME = 'Cadulang 1'),1001,1002),

      ('Tan Residence', 'Private', 'Private property', 'Behind the elementary school',
       (SELECT INFO_ID FROM INFRASTRUCTURE_OWNER WHERE INFO_LNAME = 'Tan' AND INFO_FNAME = 'Michael'),
       (SELECT INFT_ID FROM INFRASTRUCTURE_TYPE WHERE INFT_TYPE_NAME = 'Barangay Hall'),
       (SELECT SITIO_ID FROM SITIO WHERE SITIO_NAME = 'Likoan'),1001,1002);



-- BUSINESS

INSERT INTO BUSINESS_TYPE (BST_ID, BST_TYPE_NAME)
VALUES
    (1, 'Sole Proprietorship'),
    (2, 'Partnership'),
    (3, 'Corporation'),
    (4, 'Cooperative'),
    (5, 'Franchise'),
    (6, 'Others');


INSERT INTO BUSINESS_INFO (
    BS_NAME,
    BS_DESCRIPTION,
    BS_STATUS,
    BS_IS_DTI,
    BS_ADDRESS,
    BST_ID,
    ENCODED_BY_SYS_ID,
    LAST_UPDATED_BY_SYS_ID,
    BS_FNAME,
    BS_LNAME,
    SITIO_ID
) VALUES
      ('Aling Nena''s Sari-sari', 'General merchandise store', 'Active', FALSE, '123 Purok Santan',
       (SELECT BST_ID FROM BUSINESS_TYPE WHERE BST_TYPE_NAME = 'Sole Proprietorship'),
       (SELECT SYS_USER_ID FROM SYSTEM_ACCOUNT WHERE SYS_USER_ID = 1001),
       (SELECT SYS_USER_ID FROM SYSTEM_ACCOUNT WHERE SYS_USER_ID = 1001),
       'Alfredo','Garcia',
       1),

      ('Marigondon Auto Repair', 'Motorcycle and bicycle repairs', 'Active', TRUE, '456 Purok Rosas',
       (SELECT BST_ID FROM BUSINESS_TYPE WHERE BST_TYPE_NAME = 'Sole Proprietorship'),
--       (SELECT BSO_ID FROM BUSINESS_OWNER WHERE BSO_LNAME = 'Ramos'),

       (SELECT SYS_USER_ID FROM SYSTEM_ACCOUNT WHERE SYS_USER_ID = 1002),
       (SELECT SYS_USER_ID FROM SYSTEM_ACCOUNT WHERE SYS_USER_ID = 1001),'Corazon',
       'Ramos',
       2);

-- HEALTH
INSERT INTO PHILHEALTH_CATEGORY (PC_CATEGORY_NAME)
VALUES
    ('Formal Economy Private'),
    ('Formal Economy Government'),
    ('Informal Economy'),
    ('NHTS'),
    ('Senior Citizen'),
    ('Indigenous People'),
    ('Unknown');

INSERT INTO PHILHEALTH (PHEA_ID_NUMBER, PHEA_MEMBERSHIP_TYPE, PC_ID)
VALUES
    ('123456789012', 'Member', (SELECT PC_ID FROM PHILHEALTH_CATEGORY WHERE PC_CATEGORY_NAME = 'Formal Economy Private')),
    ('987654321098', 'Dependent', (SELECT PC_ID FROM PHILHEALTH_CATEGORY WHERE PC_CATEGORY_NAME = 'Indigenous People'));

INSERT INTO MEDICAL_HISTORY_TYPE (MHT_TYPE_NAME)
VALUES
    ('Hypertension'),
    ('Diabetes'),
    ('Tuberculosis'),
    ('Surgery'),
    ('Others');


INSERT INTO FAMILY_PLANNING_METHOD (FPM_METHOD)
VALUES
    ('COC'),
    ('POP'),
    ('Injectables'),
    ('IUD'),
    ('Condom'),
    ('LAM'),
    ('BTL'),
    ('Implant'),
    ('SDM'),
    ('DPT'),
    ('Withdrawal'),
    ('Others');

INSERT INTO FPM_STATUS (FPMS_STATUS_NAME)
VALUES
    ('New Acceptor'),
    ('Current User'),
    ('Changing Method'),
    ('Changing Clinic'),
    ('Dropout'),
    ('Restarter');


-- EMPLOYMENT
INSERT INTO EMPLOYMENT_STATUS (ES_STATUS_NAME)
VALUES
    ('Employed'),
    ('Unemployed'),
    ('Self Employed'),
    ('Retired');



INSERT INTO EMPLOYMENT (
    EMP_OCCUPATION,
    EMP_IS_GOV_WORKER,
    ES_ID,
    CTZ_ID
) VALUES
    ('Barangay Health Worker', TRUE,
     (SELECT ES_ID FROM EMPLOYMENT_STATUS WHERE ES_STATUS_NAME = 'Employed'),
     (SELECT CTZ_ID FROM CITIZEN WHERE CTZ_LAST_NAME = 'Gonzales'));

-- TRANSACTIONS
INSERT INTO TRANSACTION_TYPE (TT_TYPE_NAME)
VALUES
    ('Barangay Clearance'),
    ('Business Permit'),
    ('Complaint');

INSERT INTO TRANSACTION_LOG (
    TL_PURPOSE,
    TL_STATUS,
    TL_FNAME,
    TL_LNAME,
    TT_ID,
    ENCODED_BY_SYS_ID,
    LAST_UPDATED_BY_SYS_ID
) VALUES
      ('For loan application', 'Approved', 'Roberto', 'Gonzales',
       (SELECT TT_ID FROM TRANSACTION_TYPE WHERE TT_TYPE_NAME = 'Barangay Clearance'),
       (SELECT SYS_USER_ID FROM SYSTEM_ACCOUNT WHERE SYS_USER_ID = 1002),
       (SELECT SYS_USER_ID FROM SYSTEM_ACCOUNT WHERE SYS_USER_ID = 1001)),

      ('New sari-sari store', 'Pending', 'Alfredo', 'Garcia',
       (SELECT TT_ID FROM TRANSACTION_TYPE WHERE TT_TYPE_NAME = 'Business Permit'),
       (SELECT SYS_USER_ID FROM SYSTEM_ACCOUNT WHERE SYS_USER_ID = 1001),
       (SELECT SYS_USER_ID FROM SYSTEM_ACCOUNT WHERE SYS_USER_ID = 1002));

-- COMPLAINTS
INSERT INTO COMPLAINANT (COMP_FNAME, COMP_LNAME, COMP_MNAME)
VALUES
    ('Lourdes', 'Santos', 'R'),
    ('Carlos', 'Reyes', 'M');

INSERT INTO HISTORY_TYPE (HIST_TYPE_NAME)
VALUES
    ('Complaint'),
    ('Violation');

INSERT INTO CITIZEN_HISTORY (
    CIHI_DESCRIPTION,
    HIST_ID,
    CTZ_ID,
    ENCODED_BY_SYS_ID,
    LAST_UPDATED_BY_SYS_ID
) VALUES
    ('Noise complaint',
     (SELECT HIST_ID FROM HISTORY_TYPE WHERE HIST_TYPE_NAME = 'Complaint'),
     (SELECT CTZ_ID FROM CITIZEN WHERE CTZ_LAST_NAME = 'Gonzales'),
     (SELECT SYS_USER_ID FROM SYSTEM_ACCOUNT WHERE SYS_USER_ID = 1002),
     (SELECT SYS_USER_ID FROM SYSTEM_ACCOUNT WHERE SYS_USER_ID = 1002));

INSERT INTO SETTLEMENT_LOG (
    SETT_COMPLAINT_DESCRIPTION,
    ENCODED_BY_SYS_ID,
    LAST_UPDATED_BY_SYS_ID,
    SETT_SETTLEMENT_DESCRIPTION,
    SETT_DATE_OF_SETTLEMENT,
    COMP_ID,
    CIHI_ID
) VALUES
    ('Loud karaoke at night', 1001, 1002, 'Warning issued to homeowner', CURRENT_DATE,
     (SELECT COMP_ID FROM COMPLAINANT WHERE COMP_LNAME = 'Santos'),
     (SELECT CIHI_ID FROM CITIZEN_HISTORY WHERE CIHI_DESCRIPTION = 'Noise complaint'));


-- Medical History
INSERT INTO MEDICAL_HISTORY (
    MH_DESCRIPTION,
    MH_DATE_DIAGNOSED,
    MHT_ID,
    CTZ_ID,
    ENCODED_BY_SYS_ID,
    LAST_UPDATED_BY_SYS_ID
) VALUES (
             'Nag hypertension',
             '2020-01-15',
             (SELECT MHT_ID FROM MEDICAL_HISTORY_TYPE WHERE MHT_TYPE_NAME = 'Hypertension'),
             (SELECT CTZ_ID FROM CITIZEN WHERE CTZ_LAST_NAME = 'Gonzales'),
             (SELECT SYS_USER_ID FROM SYSTEM_ACCOUNT WHERE SYS_USER_ID = 1002),
             (SELECT SYS_USER_ID FROM SYSTEM_ACCOUNT WHERE SYS_USER_ID = 1002)
         );


-- Family Planning
INSERT INTO FAMILY_PLANNING (
    FP_START_DATE,
    FP_END_DATE,
    CTZ_ID,
    FPMS_STATUS,
    FPM_METHOD
) VALUES
    ('2021-06-01', NULL,
     (SELECT CTZ_ID FROM CITIZEN WHERE CTZ_LAST_NAME = 'Gonzales'),
     (SELECT FPMS_ID FROM FPM_STATUS WHERE FPMS_STATUS_NAME = 'Current User'),
     (SELECT FPM_ID FROM FAMILY_PLANNING_METHOD WHERE FPM_METHOD = 'Condom'));

--
-- SELECT
--     INF.INF_ID,
--     INF.INF_NAME,
--     INF.INF_ACCESS_TYPE,
--     INF.INF_DATE_ENCODED,
--     CONCAT(IO.INFO_FNAME, ' ',COALESCE(NULLIF(LEFT(IO.INFO_MNAME, 1), '') || '. ', ''), IO.INFO_LNAME) AS INFRASTRUCTURE_OWNER,
--     IT.INFT_TYPE_NAME,
--     INF.INF_ADDRESS_DESCRIPTION,
--     S.SITIO_NAME,
--     INF.INF_DESCRIPTION
-- FROM INFRASTRUCTURE INF
-- JOIN INFRASTRUCTURE_OWNER IO ON INF.INFO_ID = IO.INFO_ID
-- JOIN INFRASTRUCTURE_TYPE IT ON INF.INFT_ID=IT.INFT_ID
-- JOIN SITIO S ON INF.SITIO_ID = S.SITIO_ID;

