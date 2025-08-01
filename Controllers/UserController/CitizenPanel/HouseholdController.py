from PySide6.QtCore import QDate
from PySide6.QtWidgets import QTableWidgetItem, QMessageBox

from Controllers.BaseFileController import BaseFileController
from Models.HouseholdModel import HouseholdModel
from Views.CitizenPanel.HouseholdView import HouseholdView
from database import Database


class HouseholdController(BaseFileController):
    def __init__(self, login_window, emp_first_name, sys_user_id, user_role, stack):
        super().__init__(login_window, emp_first_name, sys_user_id)
        self.selected_household_id = None
        self.stack = stack
        self.model = HouseholdModel(self.sys_user_id)
        self.view = HouseholdView(self)
        self.user_role = user_role
        self.sys_user_id = sys_user_id

        # Load UI
        self.cp_household_screen = self.load_ui("Resources/Uis/MainPages/CitizenPanelPages/cp_household.ui")
        self.view.setup_household_ui(self.cp_household_screen)
        self.center_on_screen()
        self.load_household_data()

        # Store references needed for navigation
        self.login_window = login_window
        self.emp_first_name = emp_first_name

    def show_update_household_popup(self):
        if not self.selected_household_id:
            QMessageBox.warning(self.cp_household_screen, "No Selection", "Please select a household to update.")
            return

        # Fetch household data
        try:
            db = Database()
            cursor = db.get_cursor()
            cursor.execute("""
                SELECT hh_house_number, hh_address, hh_ownership_status,
                       hh_home_google_link, hh_interviewer_name, hh_date_visit, hh_reviewer_name,
                       sitio_id, toilet_id, water_id
                FROM household_info
                WHERE hh_id = %s;
            """, (self.selected_household_id,))
            row = cursor.fetchone()

            if not row:
                QMessageBox.critical(self.cp_household_screen, "Error", "Household data not found.")
                return

            household_data = {
                "house_number": row[0],
                "home_address": row[1],
                "ownership_status": row[2],
                "home_google_link": row[3],
                "interviewer_name": row[4],
                "date_of_visit": str(row[5]),
                "reviewer_name": row[6],
                "sitio_id": row[7],
                "toilet_id": row[8],
                "water_id": row[9]
            }

        except Exception as e:
            QMessageBox.critical(self.cp_household_screen, "Error", f"Database error: {str(e)}")
            return
        finally:
            db.close()

        popup = self.view.show_edit_household_popup(self)
        self.prefill_edit_popup(popup, household_data)

        popup.register_buttonConfirmHousehold_SaveForm.clicked.connect(self.update_household_data)
        popup.exec_()

    def update_household_data(self):
        if not self.selected_household_id:
            QMessageBox.warning(self.cp_household_screen, "No Selection", "Please select a household to update.")
            return

        form_data = self.view.get_form_data()

        # Validate date
        if not self.validate_date(form_data["date_of_visit"]):
            QMessageBox.warning(self.cp_household_screen, "Invalid Date", "Date of Visit cannot be in the future.")
            return

        # Get and validate sitio_id
        sitio_id = self.view.popup.register_household_comboBox_Sitio.currentData()
        if sitio_id is None:
            QMessageBox.warning(self, "Invalid Input", "Please select a valid Sitio.")
            return
        try:
            sitio_id = int(sitio_id)
        except (TypeError, ValueError):
            QMessageBox.critical(self, "Error", "Invalid Sitio ID selected.")
            return

        # Get and validate toilet_id
        toilet_id = self.view.popup.register_household_comboBox_ToiletType.currentData()
        if toilet_id is None:
            QMessageBox.warning(self, "Invalid Input", "Please select a valid Toilet Type.")
            return
        try:
            toilet_id = int(toilet_id)
        except (TypeError, ValueError):
            QMessageBox.critical(self, "Error", "Invalid Toilet ID selected.")
            return

        # Get and validate water_id
        water_id = self.view.popup.register_household_comboBox_WaterSource.currentData()
        if water_id is None:
            QMessageBox.warning(self, "Invalid Input", "Please select a valid Water Source.")
            return
        try:
            water_id = int(water_id)
        except (TypeError, ValueError):
            QMessageBox.critical(self, "Error", "Invalid Water ID selected.")
            return

        try:
            db = Database()
            db.set_user_id(self.sys_user_id)  # user ID for auditing

            update_query = """
                UPDATE household_info SET
                    hh_house_number = %s,
                    sitio_id = %s,
                    hh_ownership_status = %s,
                    hh_address = %s,
                    hh_home_google_link = %s,
                    toilet_id = %s,
                    water_id = %s,
                    hh_interviewer_name = %s,
                    hh_date_visit = %s,
                    hh_reviewer_name = %s,
                    last_updated_by_sys_id = %s,
                    hh_last_updated = CURRENT_TIMESTAMP
                WHERE hh_id = %s AND hh_is_deleted = FALSE;
            """
            db.execute_with_user(update_query, (
                form_data['house_number'],
                sitio_id,
                form_data['ownership_status'],
                form_data['home_address'],
                form_data['home_google_link'],
                toilet_id,
                water_id,
                form_data['interviewer_name'],
                form_data['date_of_visit'],
                form_data['reviewer_name'],
                self.sys_user_id,
                self.selected_household_id
            ))
            db.conn.commit()
            self.view.popup.close()
            self.load_household_data()
            QMessageBox.information(self.cp_household_screen, "Success", "Household updated successfully.")
        except Exception as e:
            db.conn.rollback()
            QMessageBox.critical(self.cp_household_screen, "Update Error", f"Failed to update household: {str(e)}")
        finally:
            db.close()


    def prefill_edit_popup(self, popup, data):
        popup.register_household_homeNumber.setText(data["house_number"] or "")
        popup.register_household_homeAddress.setText(data["home_address"] or "")
        popup.register_household_comboBox_OwnershipStatus.setCurrentText(data["ownership_status"] or "")
        popup.register_household_HomeLink.setPlainText(data["home_google_link"] or "")
        popup.register_household_InterviewedBy_fullname.setText(data["interviewer_name"] or "")
        popup.register_household_ReviewedBy_fullname.setText(data["reviewer_name"] or "")

        # dropdowns by id
        popup.register_household_comboBox_Sitio.setCurrentIndex(
            popup.register_household_comboBox_Sitio.findData(data["sitio_id"])
        )
        popup.register_household_comboBox_ToiletType.setCurrentIndex(
            popup.register_household_comboBox_ToiletType.findData(data["toilet_id"])
        )
        popup.register_household_comboBox_WaterSource.setCurrentIndex(
            popup.register_household_comboBox_WaterSource.findData(data["water_id"])
        )

        try:
            qdate = QDate.fromString(data["date_of_visit"], "yyyy-MM-dd")
            popup.register_household_date_DOV.setDate(qdate if qdate.isValid() else QDate.currentDate())
        except:
            popup.register_household_date_DOV.setDate(QDate.currentDate())

    def show_register_household_popup(self):
        print("-- Register New Household Popup")
        popup = self.view.show_register_household_popup(self)
        popup.exec_()

    def get_current_date(self):
        """Returns today's date as QDate"""
        return QDate.currentDate()

    def validate_date(self, date_string):
        """Validate that the date is not in the future"""
        selected_date = QDate.fromString(date_string, "yyyy-MM-dd")
        if selected_date > QDate.currentDate():
            return False
        return True

    def validate_fields(self):
        form_data = self.view.get_form_data()
        errors = []

        # if not form_data['house_number']:
        #     errors.append("House Number is required")
        if not form_data['sitio_id']:
            errors.append("Sitio is required")
            self.view.popup.register_household_comboBox_Sitio.setStyleSheet(
                "border: 1px solid red; border-radius: 5px; padding: 5px; background-color: rgb(239, 239, 239)"
            )
        else:
            self.view.popup.register_household_comboBox_Sitio.setStyleSheet(
                "border: 1px solid gray; border-radius: 5px; padding: 5px; background-color: rgb(239, 239, 239)"
            )
        if not form_data['ownership_status']:
            errors.append("Ownership is required")
            self.view.popup.register_household_comboBox_OwnershipStatus.setStyleSheet(
                "border: 1px solid red; border-radius: 5px; padding: 5px; background-color: rgb(239, 239, 239)"
            )
        else:
            self.view.popup.register_household_comboBox_OwnershipStatus.setStyleSheet(
                "border: 1px solid gray; border-radius: 5px; padding: 5px; background-color: rgb(239, 239, 239)"
            )
        if not form_data['home_address']:
            errors.append("Home Address is required")
            self.view.popup.register_household_homeAddress.setStyleSheet(
                        "border: 1px solid red; border-radius: 5px; padding: 5px; background-color: #f2efff"
                    )
        else:
            self.view.popup.register_household_homeAddress.setStyleSheet(
                "border: 1px solid gray; border-radius: 5px; padding: 5px; background-color: #f2efff"
            )
        # if not form_data['interviewer_name']:
        #     errors.append("Interviewer Name is required")
        # if not form_data['reviewer_name']:
        #     errors.append("Reviewer Name is required")
        if not form_data['water_id']:
            errors.append("Water source is required")
            self.view.popup.register_household_comboBox_WaterSource.setStyleSheet(
                "border: 1px solid red; border-radius: 5px; padding: 5px; background-color: rgb(239, 239, 239)"
            )
        else:
            self.view.popup.register_household_comboBox_WaterSource.setStyleSheet(
                "border: 1px solid gray; border-radius: 5px; padding: 5px; background-color: rgb(239, 239, 239)"
            )
        if not form_data['toilet_id']:
            errors.append("Toilet type is required")
            self.view.popup.register_household_comboBox_ToiletType.setStyleSheet(
                "border: 1px solid red; border-radius: 5px; padding: 5px; background-color: rgb(239, 239, 239)"
            )
        else:
            self.view.popup.register_household_comboBox_ToiletType.setStyleSheet(
                "border: 1px solid gray; border-radius: 5px; padding: 5px; background-color: rgb(239, 239, 239)"
            )

        if errors:
            self.view.show_error_message(errors)
            # self.view.highlight_missing_fields(errors)
        else:
            self.save_household_data(form_data)

    def perform_household_search(self):
        search_text = self.cp_household_screen.cp_HouseholdName_fieldSearch.text().strip()

        if not search_text:
            # If empty, reload all households
            self.load_household_data()
            return

        query = """
            SELECT 
                HH.HH_ID,
                HH.HH_HOUSE_NUMBER,
                S.SITIO_NAME,
                HH.HH_OWNERSHIP_STATUS,
                HH.HH_HOME_GOOGLE_LINK,
                T.TOIL_TYPE_NAME,
                W.WATER_SOURCE_NAME,
                HH.HH_INTERVIEWER_NAME,
                HH.HH_DATE_VISIT,
                TO_CHAR(HH.HH_DATE_ENCODED, 'FMMonth FMDD, YYYY | FMHH:MI AM') AS DATE_ENCODED_FORMATTED,
                SA.SYS_FNAME || ' ' || COALESCE(LEFT(SA.SYS_MNAME, 1) || '. ', '') || SA.SYS_LNAME AS ENCODED_BY,
                TO_CHAR(HH.HH_LAST_UPDATED, 'FMMonth FMDD, YYYY | FMHH:MI AM') AS DATE_UPDATED_FORMATTED,
                HH.HH_REVIEWER_NAME,
                CASE 
                    WHEN SUA.SYS_FNAME IS NULL THEN 'System'
                    ELSE SUA.SYS_FNAME || ' ' ||
                         COALESCE(LEFT(SUA.SYS_MNAME, 1) || '. ', '') ||
                         SUA.SYS_LNAME
                END AS LAST_UPDATED_BY_NAME,
                COUNT(C.CTZ_ID) AS TOTAL_MEMBERS
            FROM HOUSEHOLD_INFO HH
            JOIN SITIO S ON HH.SITIO_ID = S.SITIO_ID
            LEFT JOIN TOILET_TYPE T ON HH.TOILET_ID = T.toil_id
            LEFT JOIN WATER_SOURCE W ON HH.WATER_ID = W.WATER_ID
            LEFT JOIN SYSTEM_ACCOUNT SA ON HH.ENCODED_BY_SYS_ID = SA.SYS_USER_ID
            LEFT JOIN SYSTEM_ACCOUNT SUA ON HH.LAST_UPDATED_BY_SYS_ID = SUA.SYS_USER_ID
            LEFT JOIN CITIZEN C ON HH.HH_ID = C.HH_ID AND C.CTZ_IS_DELETED = FALSE AND C.CTZ_IS_ALIVE = TRUE
            WHERE HH.HH_IS_DELETED = FALSE
              AND CAST(HH.HH_ID AS TEXT) ILIKE %s
            GROUP BY
                HH.HH_ID,
                HH.HH_HOUSE_NUMBER,
                S.SITIO_NAME,
                HH.HH_OWNERSHIP_STATUS,
                HH.HH_HOME_GOOGLE_LINK,
                T.TOIL_TYPE_NAME,
                W.WATER_SOURCE_NAME,
                HH.HH_INTERVIEWER_NAME,
                HH.HH_DATE_VISIT,
                HH.HH_DATE_ENCODED,
                SA.SYS_FNAME,
                SA.SYS_MNAME,
                SA.SYS_LNAME,
                HH.HH_REVIEWER_NAME,
                SUA.SYS_FNAME,
                SUA.SYS_MNAME,
                SUA.SYS_LNAME,
                HH.HH_LAST_UPDATED
            ORDER BY HH.HH_ID ASC
            LIMIT 50;
        """

        try:
            db = Database()
            cursor = db.get_cursor()
            search_pattern = f"%{search_text}%"
            cursor.execute(query, (search_pattern,))
            rows = cursor.fetchall()

            table = self.cp_household_screen.inst_tableView_List_RegHousehold
            table.setRowCount(len(rows))
            table.setColumnCount(4)
            table.setHorizontalHeaderLabels(["ID", "Total Members", "Sitio", "Date Encoded"])
            table.setColumnWidth(0, 50)
            table.setColumnWidth(1, 150)
            table.setColumnWidth(2, 200)
            table.setColumnWidth(3, 200)

            for row_idx, row_data in enumerate(rows):
                for col_idx, value in enumerate([row_data[0], row_data[14], row_data[2], row_data[9]]):
                    item = QTableWidgetItem(str(value))
                    table.setItem(row_idx, col_idx, item)

        except Exception as e:
            QMessageBox.critical(self.cp_household_screen, "Database Error", str(e))
        finally:
            if db:
                db.close()

    from PySide6.QtCore import QDate
    from PySide6.QtWidgets import QTableWidgetItem, QMessageBox

    from Controllers.BaseFileController import BaseFileController
    from Models.HouseholdModel import HouseholdModel
    from Views.CitizenPanel.HouseholdView import HouseholdView
    from database import Database

    class HouseholdController(BaseFileController):
        def __init__(self, login_window, emp_first_name, sys_user_id, user_role, stack):
            super().__init__(login_window, emp_first_name, sys_user_id)
            self.selected_household_id = None
            self.stack = stack
            self.model = HouseholdModel(self.sys_user_id)
            self.view = HouseholdView(self)
            self.user_role = user_role
            self.sys_user_id = sys_user_id

            # Load UI
            self.cp_household_screen = self.load_ui("Resources/Uis/MainPages/CitizenPanelPages/cp_household.ui")
            self.view.setup_household_ui(self.cp_household_screen)
            self.center_on_screen()
            self.load_household_data()

            # Store references needed for navigation
            self.login_window = login_window
            self.emp_first_name = emp_first_name

        def show_update_household_popup(self):
            if not self.selected_household_id:
                QMessageBox.warning(self.cp_household_screen, "No Selection", "Please select a household to update.")
                return

            # Fetch household data
            try:
                db = Database()
                cursor = db.get_cursor()
                cursor.execute("""
                    SELECT hh_house_number, hh_home_google_link, hh_ownership_status,
                           hh_home_google_link, hh_interviewer_name, hh_date_visit, hh_reviewer_name,
                           sitio_id, toilet_id, water_id
                    FROM household_info
                    WHERE hh_id = %s;
                """, (self.selected_household_id,))
                row = cursor.fetchone()

                if not row:
                    QMessageBox.critical(self.cp_household_screen, "Error", "Household data not found.")
                    return

                household_data = {
                    "house_number": row[0],
                    "home_address": row[1],
                    "ownership_status": row[2],
                    "home_google_link": row[3],
                    "interviewer_name": row[4],
                    "date_of_visit": str(row[5]),
                    "reviewer_name": row[6],
                    "sitio_id": row[7],
                    "toilet_id": row[8],
                    "water_id": row[9]
                }

            except Exception as e:
                QMessageBox.critical(self.cp_household_screen, "Error", f"Database error: {str(e)}")
                return
            finally:
                db.close()

            popup = self.view.show_edit_household_popup(self)
            self.prefill_edit_popup(popup, household_data)

            popup.register_buttonConfirmHousehold_SaveForm.clicked.connect(self.update_household_data)
            popup.exec_()

        def update_household_data(self):
            if not self.selected_household_id:
                QMessageBox.warning(self.cp_household_screen, "No Selection", "Please select a household to update.")
                return

            form_data = self.view.get_form_data()

            # Validate date
            if not self.validate_date(form_data["date_of_visit"]):
                QMessageBox.warning(self.cp_household_screen, "Invalid Date", "Date of Visit cannot be in the future.")
                return

            # Get and validate sitio_id
            sitio_id = self.view.popup.register_household_comboBox_Sitio.currentData()
            if sitio_id is None:
                QMessageBox.warning(self, "Invalid Input", "Please select a valid Sitio.")
                return
            try:
                sitio_id = int(sitio_id)
            except (TypeError, ValueError):
                QMessageBox.critical(self, "Error", "Invalid Sitio ID selected.")
                return

            # Get and validate toilet_id
            toilet_id = self.view.popup.register_household_comboBox_ToiletType.currentData()
            if toilet_id is None:
                QMessageBox.warning(self, "Invalid Input", "Please select a valid Toilet Type.")
                return
            try:
                toilet_id = int(toilet_id)
            except (TypeError, ValueError):
                QMessageBox.critical(self, "Error", "Invalid Toilet ID selected.")
                return

            # Get and validate water_id
            water_id = self.view.popup.register_household_comboBox_WaterSource.currentData()
            if water_id is None:
                QMessageBox.warning(self, "Invalid Input", "Please select a valid Water Source.")
                return
            try:
                water_id = int(water_id)
            except (TypeError, ValueError):
                QMessageBox.critical(self, "Error", "Invalid Water ID selected.")
                return

            try:
                db = Database()
                db.set_user_id(self.sys_user_id)  # user ID for auditing

                update_query = """
                    UPDATE household_info SET
                        hh_house_number = %s,
                        sitio_id = %s,
                        hh_ownership_status = %s,
                        hh_home_google_link = %s,
                        toilet_id = %s,
                        water_id = %s,
                        hh_interviewer_name = %s,
                        hh_date_visit = %s,
                        hh_reviewer_name = %s,
                        last_updated_by_sys_id = %s,
                        hh_last_updated = CURRENT_TIMESTAMP
                    WHERE hh_id = %s AND hh_is_deleted = FALSE;
                """
                db.execute_with_user(update_query, (
                    form_data['house_number'],
                    sitio_id,
                    form_data['ownership_status'],
                    form_data['home_address'],
                    toilet_id,
                    water_id,
                    form_data['interviewer_name'],
                    form_data['date_of_visit'],
                    form_data['reviewer_name'],
                    self.sys_user_id,
                    self.selected_household_id
                ))
                db.conn.commit()
                self.view.popup.close()
                self.load_household_data()
                QMessageBox.information(self.cp_household_screen, "Success", "Household updated successfully.")
            except Exception as e:
                db.conn.rollback()
                QMessageBox.critical(self.cp_household_screen, "Update Error", f"Failed to update household: {str(e)}")
            finally:
                db.close()

        def prefill_edit_popup(self, popup, data):
            popup.register_household_homeNumber.setText(data["house_number"] or "")
            popup.register_household_homeAddress.setText(data["home_address"] or "")
            popup.register_household_comboBox_OwnershipStatus.setCurrentText(data["ownership_status"] or "")
            popup.register_household_HomeLink.setPlainText(data["home_google_link"] or "")
            popup.register_household_InterviewedBy_fullname.setText(data["interviewer_name"] or "")
            popup.register_household_ReviewedBy_fullname.setText(data["reviewer_name"] or "")

            # dropdowns by id
            popup.register_household_comboBox_Sitio.setCurrentIndex(
                popup.register_household_comboBox_Sitio.findData(data["sitio_id"])
            )
            popup.register_household_comboBox_ToiletType.setCurrentIndex(
                popup.register_household_comboBox_ToiletType.findData(data["toilet_id"])
            )
            popup.register_household_comboBox_WaterSource.setCurrentIndex(
                popup.register_household_comboBox_WaterSource.findData(data["water_id"])
            )

            try:
                qdate = QDate.fromString(data["date_of_visit"], "yyyy-MM-dd")
                popup.register_household_date_DOV.setDate(qdate if qdate.isValid() else QDate.currentDate())
            except:
                popup.register_household_date_DOV.setDate(QDate.currentDate())

        def show_register_household_popup(self):
            print("-- Register New Household Popup")
            popup = self.view.show_register_household_popup(self)
            popup.exec_()

        def get_current_date(self):
            """Returns today's date as QDate"""
            return QDate.currentDate()

        def validate_date(self, date_string):
            """Validate that the date is not in the future"""
            selected_date = QDate.fromString(date_string, "yyyy-MM-dd")
            if selected_date > QDate.currentDate():
                return False
            return True

        def validate_fields(self):
            form_data = self.view.get_form_data()
            errors = []

            # if not form_data['house_number']:
            #     errors.append("House Number is required")
            if not form_data['sitio_id']:
                errors.append("Sitio is required")
                self.view.popup.register_household_comboBox_Sitio.setStyleSheet(
                    "border: 1px solid red; border-radius: 5px; padding: 5px; background-color: rgb(239, 239, 239)"
                )
            else:
                self.view.popup.register_household_comboBox_Sitio.setStyleSheet(
                    "border: 1px solid gray; border-radius: 5px; padding: 5px; background-color: rgb(239, 239, 239)"
                )
            if not form_data['ownership_status']:
                errors.append("Ownership is required")
                self.view.popup.register_household_comboBox_OwnershipStatus.setStyleSheet(
                    "border: 1px solid red; border-radius: 5px; padding: 5px; background-color: rgb(239, 239, 239)"
                )
            else:
                self.view.popup.register_household_comboBox_OwnershipStatus.setStyleSheet(
                    "border: 1px solid gray; border-radius: 5px; padding: 5px; background-color: rgb(239, 239, 239)"
                )
            if not form_data['home_address']:
                errors.append("Home Address is required")
                self.view.popup.register_household_homeAddress.setStyleSheet(
                    "border: 1px solid red; border-radius: 5px; padding: 5px; background-color: #f2efff"
                )
            else:
                self.view.popup.register_household_homeAddress.setStyleSheet(
                    "border: 1px solid gray; border-radius: 5px; padding: 5px; background-color: #f2efff"
                )
            # if not form_data['interviewer_name']:
            #     errors.append("Interviewer Name is required")
            # if not form_data['reviewer_name']:
            #     errors.append("Reviewer Name is required")
            if not form_data['water_id']:
                errors.append("Water source is required")
                self.view.popup.register_household_comboBox_WaterSource.setStyleSheet(
                    "border: 1px solid red; border-radius: 5px; padding: 5px; background-color: rgb(239, 239, 239)"
                )
            else:
                self.view.popup.register_household_comboBox_WaterSource.setStyleSheet(
                    "border: 1px solid gray; border-radius: 5px; padding: 5px; background-color: rgb(239, 239, 239)"
                )
            if not form_data['toilet_id']:
                errors.append("Toilet type is required")
                self.view.popup.register_household_comboBox_ToiletType.setStyleSheet(
                    "border: 1px solid red; border-radius: 5px; padding: 5px; background-color: rgb(239, 239, 239)"
                )
            else:
                self.view.popup.register_household_comboBox_ToiletType.setStyleSheet(
                    "border: 1px solid gray; border-radius: 5px; padding: 5px; background-color: rgb(239, 239, 239)"
                )

            if errors:
                self.view.show_error_message(errors)
                # self.view.highlight_missing_fields(errors)
            else:
                self.save_household_data(form_data)

        def perform_household_search(self):
            search_text = self.cp_household_screen.cp_HouseholdName_fieldSearch.text().strip()

            if not search_text:
                # If empty, reload all households
                self.load_household_data()
                return

            query = """
                SELECT 
                    HH.HH_ID,
                    HH.HH_HOUSE_NUMBER,
                    S.SITIO_NAME,
                    HH.HH_OWNERSHIP_STATUS,
                    HH.HH_HOME_GOOGLE_LINK,
                    T.TOIL_TYPE_NAME,
                    W.WATER_SOURCE_NAME,
                    HH.HH_INTERVIEWER_NAME,
                    HH.HH_DATE_VISIT,
                    TO_CHAR(HH.HH_DATE_ENCODED, 'FMMonth FMDD, YYYY | FMHH:MI AM') AS DATE_ENCODED_FORMATTED,
                    SA.SYS_FNAME || ' ' || COALESCE(LEFT(SA.SYS_MNAME, 1) || '. ', '') || SA.SYS_LNAME AS ENCODED_BY,
                    TO_CHAR(HH.HH_LAST_UPDATED, 'FMMonth FMDD, YYYY | FMHH:MI AM') AS DATE_UPDATED_FORMATTED,
                    HH.HH_REVIEWER_NAME,
                    CASE 
                        WHEN SUA.SYS_FNAME IS NULL THEN 'System'
                        ELSE SUA.SYS_FNAME || ' ' ||
                             COALESCE(LEFT(SUA.SYS_MNAME, 1) || '. ', '') ||
                             SUA.SYS_LNAME
                    END AS LAST_UPDATED_BY_NAME,
                    COUNT(C.CTZ_ID) AS TOTAL_MEMBERS
                FROM HOUSEHOLD_INFO HH
                JOIN SITIO S ON HH.SITIO_ID = S.SITIO_ID
                LEFT JOIN TOILET_TYPE T ON HH.TOILET_ID = T.toil_id
                LEFT JOIN WATER_SOURCE W ON HH.WATER_ID = W.WATER_ID
                LEFT JOIN SYSTEM_ACCOUNT SA ON HH.ENCODED_BY_SYS_ID = SA.SYS_USER_ID
                LEFT JOIN SYSTEM_ACCOUNT SUA ON HH.LAST_UPDATED_BY_SYS_ID = SUA.SYS_USER_ID
                LEFT JOIN CITIZEN C ON HH.HH_ID = C.HH_ID AND C.CTZ_IS_DELETED = FALSE AND C.CTZ_IS_ALIVE = TRUE
                WHERE HH.HH_IS_DELETED = FALSE
                  AND CAST(HH.HH_ID AS TEXT) ILIKE %s
                GROUP BY
                    HH.HH_ID,
                    HH.HH_HOUSE_NUMBER,
                    S.SITIO_NAME,
                    HH.HH_OWNERSHIP_STATUS,
                    HH.HH_HOME_GOOGLE_LINK,
                    T.TOIL_TYPE_NAME,
                    W.WATER_SOURCE_NAME,
                    HH.HH_INTERVIEWER_NAME,
                    HH.HH_DATE_VISIT,
                    HH.HH_DATE_ENCODED,
                    SA.SYS_FNAME,
                    SA.SYS_MNAME,
                    SA.SYS_LNAME,
                    HH.HH_REVIEWER_NAME,
                    SUA.SYS_FNAME,
                    SUA.SYS_MNAME,
                    SUA.SYS_LNAME,
                    HH.HH_LAST_UPDATED
                ORDER BY HH.HH_ID ASC
                LIMIT 50;
            """

            try:
                db = Database()
                cursor = db.get_cursor()
                search_pattern = f"%{search_text}%"
                cursor.execute(query, (search_pattern,))
                rows = cursor.fetchall()

                table = self.cp_household_screen.inst_tableView_List_RegHousehold
                table.setRowCount(len(rows))
                table.setColumnCount(4)
                table.setHorizontalHeaderLabels(["ID", "Total Members", "Sitio", "Date Encoded"])
                table.setColumnWidth(0, 50)
                table.setColumnWidth(1, 150)
                table.setColumnWidth(2, 200)
                table.setColumnWidth(3, 200)

                for row_idx, row_data in enumerate(rows):
                    for col_idx, value in enumerate([row_data[0], row_data[14], row_data[2], row_data[9]]):
                        item = QTableWidgetItem(str(value))
                        table.setItem(row_idx, col_idx, item)

            except Exception as e:
                QMessageBox.critical(self.cp_household_screen, "Database Error", str(e))
            finally:
                if db:
                    db.close()

        def handle_remove_household(self):
            if not hasattr(self, 'selected_household_id') or self.selected_household_id is None:
                QMessageBox.warning(self.cp_household_screen, "No Selection", "Please select a household to remove.")
                return

            hh_id = self.selected_household_id

            confirm = QMessageBox.question(
                self.cp_household_screen,
                "Confirm Deletion",
                f"Are you sure you want to delete household with ID {hh_id}?",
                QMessageBox.Yes | QMessageBox.No,
                QMessageBox.No
            )

            if confirm != QMessageBox.Yes:
                return

            try:
                db = Database()
                db.set_user_id(self.sys_user_id)  # user ID for auditing
                db.execute_with_user("""
                    UPDATE household_info
                    SET hh_is_deleted = TRUE
                    WHERE hh_id = %s;
                """, (hh_id,))
                db.conn.commit()
                QMessageBox.information(self.cp_household_screen, "Success", f"Household {hh_id} has been deleted.")
                self.load_household_data()  # Refresh table
                if hasattr(self, 'selected_household_id'):
                    delattr(self, 'selected_household_id')  # Clear selection
            except Exception as e:
                db.conn.rollback()
                QMessageBox.critical(self.cp_household_screen, "Database Error",
                                     f"Failed to delete household: {str(e)}")
            finally:
                db.close()

        def load_household_data(self):
            connection = None
            try:
                connection = Database()
                cursor = connection.cursor
                cursor.execute("""
                    SELECT 
                        HH.HH_ID, -- 0
                        HH.HH_HOUSE_NUMBER, -- 1
                        S.SITIO_NAME, -- 2
                        HH.HH_OWNERSHIP_STATUS, -- 3
                        HH.HH_HOME_GOOGLE_LINK, -- 4
                        T.TOIL_TYPE_NAME, -- 5
                        W.WATER_SOURCE_NAME, -- 6
                        HH.HH_INTERVIEWER_NAME, -- 7
                        HH.HH_DATE_VISIT, -- 8
                        TO_CHAR(HH.HH_DATE_ENCODED, 'FMMonth FMDD, YYYY | FMHH:MI AM') AS DATE_ENCODED_FORMATTED, -- 9
                        SA.SYS_FNAME || ' ' || COALESCE(LEFT(SA.SYS_MNAME, 1) || '. ', '') || SA.SYS_LNAME AS ENCODED_BY, -- 10
                        TO_CHAR(HH.HH_LAST_UPDATED, 'FMMonth FMDD, YYYY | FMHH:MI AM') AS DATE_UPDATED_FORMATTED, -- 11
                        HH.HH_REVIEWER_NAME, -- 12
                        CASE 
                            WHEN SUA.SYS_FNAME IS NULL THEN 'System'
                            ELSE SUA.SYS_FNAME || ' ' ||
                                 COALESCE(LEFT(SUA.SYS_MNAME, 1) || '. ', '') ||
                                 SUA.SYS_LNAME
                        END AS LAST_UPDATED_BY_NAME, -- 13
                        COUNT(C.CTZ_ID) AS TOTAL_MEMBERS -- Total members from CITIZEN
                    FROM HOUSEHOLD_INFO HH
                    JOIN SITIO S ON HH.SITIO_ID = S.SITIO_ID
                    LEFT JOIN TOILET_TYPE T ON HH.TOILET_ID = T.toil_id
                    LEFT JOIN WATER_SOURCE W ON HH.WATER_ID = W.WATER_ID
                    LEFT JOIN SYSTEM_ACCOUNT SA ON HH.ENCODED_BY_SYS_ID = SA.SYS_USER_ID
                    LEFT JOIN SYSTEM_ACCOUNT SUA ON HH.LAST_UPDATED_BY_SYS_ID = SUA.SYS_USER_ID
                    LEFT JOIN CITIZEN C ON HH.HH_ID = C.HH_ID AND C.CTZ_IS_DELETED = FALSE AND C.CTZ_IS_ALIVE = TRUE
                    WHERE HH.HH_IS_DELETED = FALSE
                    GROUP BY
                        HH.HH_ID,
                        HH.HH_HOUSE_NUMBER,
                        S.SITIO_NAME,
                        HH.HH_OWNERSHIP_STATUS,
                        HH.HH_HOME_GOOGLE_LINK,
                        T.TOIL_TYPE_NAME,
                        W.WATER_SOURCE_NAME,
                        HH.HH_INTERVIEWER_NAME,
                        HH.HH_DATE_VISIT,
                        HH.HH_DATE_ENCODED,
                        SA.SYS_FNAME,
                        SA.SYS_MNAME,
                        SA.SYS_LNAME,
                        HH.HH_REVIEWER_NAME,
                        SUA.SYS_FNAME,
                        SUA.SYS_MNAME,
                        SUA.SYS_LNAME,
                        HH.HH_LAST_UPDATED
                    ORDER BY HH.HH_ID DESC
                    LIMIT 50;
                """)
                rows = cursor.fetchall()
                self.household_rows = rows

                table = self.cp_household_screen.inst_tableView_List_RegHousehold
                table.setRowCount(len(rows))
                table.setColumnCount(4)
                table.setHorizontalHeaderLabels(["ID", "Total Members", "Sitio", "Date Encoded"])

                table.setColumnWidth(0, 50)
                table.setColumnWidth(1, 150)
                table.setColumnWidth(2, 200)
                table.setColumnWidth(3, 200)

                for row_idx, row_data in enumerate(rows):
                    # col 1 now shows total members instead of household number
                    for col_idx, value in enumerate([row_data[0], row_data[14], row_data[2], row_data[9]]):
                        item = QTableWidgetItem(str(value))
                        table.setItem(row_idx, col_idx, item)

            except Exception as e:
                QMessageBox.critical(self.cp_household_screen, "Database Error", str(e))
            finally:
                if connection:
                    connection.close()

        def display_family_members(self, hh_id):
            """
            Fetches and displays family members of the selected household,
            including their relationship names from the RELATIONSHIP_TYPE table.
            """
            connection = None
            try:
                connection = Database()
                cursor = connection.cursor

                query = """
                    SELECT 
                        C.CTZ_FIRST_NAME,
                        C.CTZ_LAST_NAME,
                        R.RTH_RELATIONSHIP_NAME
                    FROM CITIZEN C
                    JOIN RELATIONSHIP_TYPE R ON C.RTH_ID = R.RTH_ID
                    WHERE C.HH_ID = %s AND C.CTZ_IS_DELETED = FALSE;
                """
                cursor.execute(query, (hh_id,))
                rows = cursor.fetchall()

                table = self.cp_household_screen.cp_tableView_List_DisplayFamilyMembers
                table.setRowCount(len(rows))
                table.setColumnCount(3)
                table.setHorizontalHeaderLabels(["First Name", "Last Name", "Relationship"])
                table.setColumnWidth(0, 150)
                table.setColumnWidth(1, 150)
                table.setColumnWidth(2, 200)

                for row_idx, row_data in enumerate(rows):
                    for col_idx, value in enumerate(row_data):
                        item = QTableWidgetItem(str(value))
                        table.setItem(row_idx, col_idx, item)

            except Exception as e:
                QMessageBox.critical(self.cp_household_screen, "Database Error", str(e))
            finally:
                if connection:
                    connection.close()

        def handle_row_click_household(self, row, column):
            table = self.cp_household_screen.inst_tableView_List_RegHousehold
            selected_item = table.item(row, 0)
            if not selected_item:
                return

            selected_id = selected_item.text()

            for record in self.household_rows:
                if str(record[0]) == selected_id:
                    self.cp_household_screen.cp_displayHouseholdNum.setText(str(record[1]))  # HH Number
                    self.cp_household_screen.cp_displayHouseholdID.setText(str(record[0]))  # HH ID
                    self.cp_household_screen.cp_displaySitio.setText(record[2])  # Sitio Name
                    self.cp_household_screen.cp_displayOwnershipStatus.setText(record[3] or "None")  # Ownership Status
                    from PySide6.QtCore import Qt
                    from PySide6.QtWidgets import QLabel

                    link = record[4]
                    label: QLabel = self.cp_household_screen.cp_displayHomeLink

                    if link:
                        label.setText(f'<a href="{link}">Google Link</a>')

                        # Combine flags properly
                        interaction_flags = Qt.TextInteractionFlag.TextSelectableByMouse | Qt.TextInteractionFlag.LinksAccessibleByMouse
                        label.setTextInteractionFlags(Qt.TextInteractionFlag(interaction_flags))

                        label.setOpenExternalLinks(True)
                        label.setStyleSheet("QLabel { color: blue; text-decoration: underline; }")
                    else:
                        label.setText("None")
                        label.setTextInteractionFlags(Qt.TextInteractionFlag.NoTextInteraction)
                    self.cp_household_screen.cp_DisplayToiletType.setText(record[5] or "None")  # Toilet Type
                    self.cp_household_screen.cp_displayWaterSource.setText(record[6] or "None")  # Water Source
                    self.cp_household_screen.cp_displayInterviewedBy.setText(record[7] or "None")  # Interviewer
                    self.cp_household_screen.cp_displayDateofVisit.setText(
                        record[8].strftime('%B %d, %Y') if record[8] else "None"
                    )  # Date of Visit
                    self.cp_household_screen.display_DateEncoded.setText(record[9] or "None")  # Date Encoded
                    self.cp_household_screen.display_EncodedBy.setText(record[10] or "System")  # Encoded By
                    self.cp_household_screen.display_DateUpdated.setText(record[11] or "None")  # Last Updated
                    self.cp_household_screen.cp_displayReviewedBy.setText(record[12] or "None")
                    self.cp_household_screen.display_UpdatedBy.setText(record[13] or "None")
                    # Store selected household ID
                    self.selected_household_id = selected_id
                    self.display_family_members(int(selected_id))
                    # self.cp_household_screen.display_UpdatedBy.setText(record[12] or "System")  # Updated By

                    break

        def save_household_data(self, form_data):
            if not self.view.confirm_registration():
                return

            if self.model.save_household_data(form_data):
                self.view.show_success_message()
                self.view.popup.close()
                self.load_household_data()
            else:
                self.view.show_error_dialog("Database error occurred")

        def upload_image(self):
            file_path = self.view.get_file_path()
            if file_path:
                saved_path = self.model.save_image(file_path)
                self.view.show_image_preview(file_path)

        def goto_citizen_panel(self):
            """Handle navigation to Citizen Panel screen."""
            print("-- Navigating to Citizen Panel")
            if not hasattr(self, 'citizen_panel'):
                from Controllers.UserController.CitizenPanelController import CitizenPanelController
                self.citizen_panel = CitizenPanelController(self.login_window, self.emp_first_name, self.sys_user_id,
                                                            self.user_role, self.stack)
                self.stack.addWidget(self.citizen_panel.citizen_panel_screen)

            self.stack.setCurrentWidget(self.citizen_panel.citizen_panel_screen)

            # self.stack.setCurrentWidget(self.citizen_panel.citizen_panel_screen)
            self.setWindowTitle("MaPro: Citizen Panel")

    def reset_household_profile_display(self):
        # Basic Info
        self.cp_household_screen.cp_displayHouseholdID.setText("N/A")
        self.cp_household_screen.cp_displayHouseholdNum.setText("N/A")
        self.cp_household_screen.cp_displaySitio.setText("N/A")
        self.cp_household_screen.cp_displayOwnershipStatus.setText("N/A")

        # Address / Location
        self.cp_household_screen.cp_displayHomeLink.setText("N/A")
        self.cp_household_screen.cp_DisplayToiletType.setText("N/A")
        self.cp_household_screen.cp_displayWaterSource.setText("N/A")

        # Interviewer Info
        self.cp_household_screen.cp_displayInterviewedBy.setText("N/A")
        self.cp_household_screen.cp_displayDateofVisit.setText("N/A")
        self.cp_household_screen.cp_displayReviewedBy.setText("N/A")

        # Timestamps
        self.cp_household_screen.display_DateEncoded.setText("N/A")
        self.cp_household_screen.display_EncodedBy.setText("N/A")
        self.cp_household_screen.display_DateUpdated.setText("N/A")
        self.cp_household_screen.display_UpdatedBy.setText("N/A")

        # Family Members Table
        family_table = self.cp_household_screen.cp_tableView_List_DisplayFamilyMembers
        family_table.setRowCount(0)

    def handle_remove_household(self):
        if not hasattr(self, 'selected_household_id') or self.selected_household_id is None:
            QMessageBox.warning(self.cp_household_screen, "No Selection", "Please select a household to remove.")
            return

        hh_id = self.selected_household_id
        confirm = QMessageBox.question(
            self.cp_household_screen,
            "Confirm Deletion",
            f"Are you sure you want to delete household with ID {hh_id}?",
            QMessageBox.Yes | QMessageBox.No,
            QMessageBox.No
        )
        if confirm != QMessageBox.Yes:
            return

        try:
            db = Database()
            db.set_user_id(self.sys_user_id)  # user ID for auditing

            db.execute_with_user("""
                UPDATE household_info
                SET hh_is_deleted = TRUE
                WHERE hh_id = %s;
            """, (hh_id,))

            db.conn.commit()

            QMessageBox.information(self.cp_household_screen, "Success", f"Household {hh_id} has been deleted.")
            self.load_household_data()  # Refresh table
            self.reset_household_profile_display()  # Clear profile display

            if hasattr(self, 'selected_household_id'):
                delattr(self, 'selected_household_id')  # Clear selection

        except Exception as e:
            db.conn.rollback()
            QMessageBox.critical(self.cp_household_screen, "Database Error", f"Failed to delete household: {str(e)}")
        finally:
            db.close()

    def load_household_data(self):
        connection = None
        try:
            connection = Database()
            cursor = connection.cursor
            cursor.execute("""
                SELECT 
                    HH.HH_ID, -- 0
                    HH.HH_HOUSE_NUMBER, -- 1
                    S.SITIO_NAME, -- 2
                    HH.HH_OWNERSHIP_STATUS, -- 3
                    HH.HH_HOME_GOOGLE_LINK, -- 4
                    T.TOIL_TYPE_NAME, -- 5
                    W.WATER_SOURCE_NAME, -- 6
                    HH.HH_INTERVIEWER_NAME, -- 7
                    HH.HH_DATE_VISIT, -- 8
                    TO_CHAR(HH.HH_DATE_ENCODED, 'FMMonth FMDD, YYYY | FMHH:MI AM') AS DATE_ENCODED_FORMATTED, -- 9
                    SA.SYS_FNAME || ' ' || COALESCE(LEFT(SA.SYS_MNAME, 1) || '. ', '') || SA.SYS_LNAME AS ENCODED_BY, -- 10
                    TO_CHAR(HH.HH_LAST_UPDATED, 'FMMonth FMDD, YYYY | FMHH:MI AM') AS DATE_UPDATED_FORMATTED, -- 11
                    HH.HH_REVIEWER_NAME, -- 12
                    CASE 
                        WHEN SUA.SYS_FNAME IS NULL THEN 'System'
                        ELSE SUA.SYS_FNAME || ' ' ||
                             COALESCE(LEFT(SUA.SYS_MNAME, 1) || '. ', '') ||
                             SUA.SYS_LNAME
                    END AS LAST_UPDATED_BY_NAME, -- 13
                    HH.HH_ADDRESS, -- 14
                    COUNT(C.CTZ_ID) AS TOTAL_MEMBERS -- Total members from CITIZEN
                FROM HOUSEHOLD_INFO HH
                JOIN SITIO S ON HH.SITIO_ID = S.SITIO_ID
                LEFT JOIN TOILET_TYPE T ON HH.TOILET_ID = T.toil_id
                LEFT JOIN WATER_SOURCE W ON HH.WATER_ID = W.WATER_ID
                LEFT JOIN SYSTEM_ACCOUNT SA ON HH.ENCODED_BY_SYS_ID = SA.SYS_USER_ID
                LEFT JOIN SYSTEM_ACCOUNT SUA ON HH.LAST_UPDATED_BY_SYS_ID = SUA.SYS_USER_ID
                LEFT JOIN CITIZEN C ON HH.HH_ID = C.HH_ID AND C.CTZ_IS_DELETED = FALSE AND C.CTZ_IS_ALIVE = TRUE
                WHERE HH.HH_IS_DELETED = FALSE
                GROUP BY
                    HH.HH_ID,
                    HH.HH_HOUSE_NUMBER,
                    S.SITIO_NAME,
                    HH.HH_OWNERSHIP_STATUS,
                    HH.HH_HOME_GOOGLE_LINK,
                    T.TOIL_TYPE_NAME,
                    W.WATER_SOURCE_NAME,
                    HH.HH_INTERVIEWER_NAME,
                    HH.HH_DATE_VISIT,
                    HH.HH_DATE_ENCODED,
                    SA.SYS_FNAME,
                    SA.SYS_MNAME,
                    SA.SYS_LNAME,
                    HH.HH_REVIEWER_NAME,
                    SUA.SYS_FNAME,
                    SUA.SYS_MNAME,
                    SUA.SYS_LNAME,
                    HH.HH_LAST_UPDATED
                ORDER BY HH.HH_ID DESC
                LIMIT 50;
            """)
            rows = cursor.fetchall()
            self.household_rows = rows

            table = self.cp_household_screen.inst_tableView_List_RegHousehold
            table.setRowCount(len(rows))
            table.setColumnCount(4)
            table.setHorizontalHeaderLabels(["ID", "Total Members", "Sitio", "Date Encoded"])

            table.setColumnWidth(0, 50)
            table.setColumnWidth(1, 150)
            table.setColumnWidth(2, 200)
            table.setColumnWidth(3, 200)

            for row_idx, row_data in enumerate(rows):
                # col 1 now shows total members instead of household number
                for col_idx, value in enumerate([row_data[0], row_data[15], row_data[2], row_data[9]]):
                    item = QTableWidgetItem(str(value))
                    table.setItem(row_idx, col_idx, item)

        except Exception as e:
            QMessageBox.critical(self.cp_household_screen, "Database Error", str(e))
        finally:
            if connection:
                connection.close()

    def display_family_members(self, hh_id):
        """
        Fetches and displays family members of the selected household,
        including their relationship names from the RELATIONSHIP_TYPE table.
        """
        connection = None
        try:
            connection = Database()
            cursor = connection.cursor

            query = """
                SELECT 
                    C.CTZ_FIRST_NAME,
                    C.CTZ_LAST_NAME,
                    R.RTH_RELATIONSHIP_NAME
                FROM CITIZEN C
                JOIN RELATIONSHIP_TYPE R ON C.RTH_ID = R.RTH_ID
                WHERE C.HH_ID = %s AND C.CTZ_IS_DELETED = FALSE;
            """
            cursor.execute(query, (hh_id,))
            rows = cursor.fetchall()

            table = self.cp_household_screen.cp_tableView_List_DisplayFamilyMembers
            table.setRowCount(len(rows))
            table.setColumnCount(3)
            table.setHorizontalHeaderLabels(["First Name", "Last Name", "Relationship"])
            table.setColumnWidth(0, 150)
            table.setColumnWidth(1, 150)
            table.setColumnWidth(2, 200)

            for row_idx, row_data in enumerate(rows):
                for col_idx, value in enumerate(row_data):
                    item = QTableWidgetItem(str(value))
                    table.setItem(row_idx, col_idx, item)

        except Exception as e:
            QMessageBox.critical(self.cp_household_screen, "Database Error", str(e))
        finally:
            if connection:
                connection.close()



    def handle_row_click_household(self, row, column):
        table = self.cp_household_screen.inst_tableView_List_RegHousehold
        selected_item = table.item(row, 0)
        if not selected_item:
            return

        selected_id = selected_item.text()

        for record in self.household_rows:
            if str(record[0]) == selected_id:
                self.cp_household_screen.cp_displayHouseholdNum.setText(str(record[1]))  # HH Number
                self.cp_household_screen.cp_displayHouseholdID.setText(str(record[0]))  # HH ID
                self.cp_household_screen.cp_displaySitio.setText(record[2])  # Sitio Name
                self.cp_household_screen.cp_displayOwnershipStatus.setText(record[3] or "None")  # Ownership Status
                from PySide6.QtCore import Qt
                from PySide6.QtWidgets import QLabel


                link = record[4]
                label: QLabel = self.cp_household_screen.cp_displayHomeLink

                if link:
                    label.setText(f'<a href="{link}">Google Link</a>')

                    # Combine flags properly
                    interaction_flags = Qt.TextInteractionFlag.TextSelectableByMouse | Qt.TextInteractionFlag.LinksAccessibleByMouse
                    label.setTextInteractionFlags(Qt.TextInteractionFlag(interaction_flags))

                    label.setOpenExternalLinks(True)
                    label.setStyleSheet("QLabel { color: blue; text-decoration: underline; }")
                else:
                    label.setText("None")
                    label.setTextInteractionFlags(Qt.TextInteractionFlag.NoTextInteraction)
                self.cp_household_screen.cp_DisplayToiletType.setText(record[5] or "None")  # Toilet Type
                self.cp_household_screen.cp_displayWaterSource.setText(record[6] or "None")  # Water Source
                self.cp_household_screen.cp_displayInterviewedBy.setText(record[7] or "None")  # Interviewer
                self.cp_household_screen.cp_displayDateofVisit.setText(
                    record[8].strftime('%B %d, %Y') if record[8] else "None"
                )  # Date of Visit
                self.cp_household_screen.display_DateEncoded.setText(record[9] or "None")  # Date Encoded
                self.cp_household_screen.cp_displayaddress.setText(record[14] or "None")
                self.cp_household_screen.display_EncodedBy.setText(record[10] or "System")  # Encoded By
                self.cp_household_screen.display_DateUpdated.setText(record[11] or "None")  # Last Updated
                self.cp_household_screen.cp_displayReviewedBy.setText(record[12] or "None")
                self.cp_household_screen.display_UpdatedBy.setText(record[13] or "None")
                # Store selected household ID
                self.selected_household_id = selected_id
                self.display_family_members(int(selected_id))
                # self.cp_household_screen.display_UpdatedBy.setText(record[12] or "System")  # Updated By

                break

    def save_household_data(self, form_data):
        if not self.view.confirm_registration():
            return


        if self.model.save_household_data(form_data):
            self.view.show_success_message()
            self.view.popup.close()
            self.load_household_data()
        else:
            self.view.show_error_dialog("Database error occurred")

    def upload_image(self):
        file_path = self.view.get_file_path()
        if file_path:
            saved_path = self.model.save_image(file_path)
            self.view.show_image_preview(file_path)

    def goto_citizen_panel(self):
        """Handle navigation to Citizen Panel screen."""
        print("-- Navigating to Citizen Panel")
        if not hasattr(self, 'citizen_panel'):
            from Controllers.UserController.CitizenPanelController import CitizenPanelController
            self.citizen_panel = CitizenPanelController(self.login_window, self.emp_first_name, self.sys_user_id, self.user_role, self.stack)
            self.stack.addWidget(self.citizen_panel.citizen_panel_screen)

        self.stack.setCurrentWidget(self.citizen_panel.citizen_panel_screen)

        # self.stack.setCurrentWidget(self.citizen_panel.citizen_panel_screen)
        self.setWindowTitle("MaPro: Citizen Panel")