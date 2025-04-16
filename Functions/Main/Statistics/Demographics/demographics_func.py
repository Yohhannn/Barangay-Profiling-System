from PySide6.QtGui import QPixmap, QIcon, Qt, QImage
from PySide6.QtCore import QTimer
from PySide6.QtWidgets import QMessageBox

from Functions.base_file_func import base_file_func
from Utils.utils_datetime import update_date_label
from Utils.util_popup import load_popup

class demographics_func(base_file_func):
    def __init__(self, login_window, emp_first_name, stack):
        super().__init__(login_window, emp_first_name)
        self.stack = stack
        self.stat_demo_screen = self.load_ui("UI/MainPages/StatisticPages/demographic.ui")
        self.setup_demo_ui()
        self.center_on_screen()

    def setup_demo_ui(self):
        """Setup the Demographics UI layout."""
        self.setFixedSize(1350, 850)
        self.setWindowTitle("MaPro: Demographics")
        self.setWindowIcon(QIcon("Assets/AppIcons/appicon_active_u.ico"))

    # Set images and icons
        self.stat_demo_screen.btn_returnToStatisticsPage.setIcon(QIcon('Assets/FuncIcons/img_return.png'))
        self.stat_demo_screen.icon_male.setIcon(QIcon('Assets/Icons/icon_male.png'))
        self.stat_demo_screen.icon_female.setIcon(QIcon('Assets/Icons/icon_female.png'))

        # Return Button
        self.stat_demo_screen.btn_returnToStatisticsPage.clicked.connect(self.goto_statistics_panel)

    def goto_statistics_panel(self):
        """Handle navigation to Statistics Panel screen."""
        print("-- Navigating to Statistics")
        if not hasattr(self, 'statistics_panel'):
            from Functions.Main.Statistics.statistics_func import statistics_func
            self.statistics_panel = statistics_func(self.login_window, self.emp_first_name, self.stack)
            self.stack.addWidget(self.statistics_panel.statistics_screen)

        self.stack.setCurrentWidget(self.statistics_panel.statistics_screen)
        self.setWindowTitle("MaPro: Statistics")