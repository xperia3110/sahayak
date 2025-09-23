# Backend Setup Instructions

## Prerequisites
- Python 3.8 or higher
- pip (Python package installer)

## Setup Steps

1. **Clone the repository** (if not already done)
   ```bash
   git clone <your-repo-url>
   cd <project-directory>/backend
   ```

2. **Create a virtual environment**
   ```bash
   python -m venv venv
   ```

3. **Activate the virtual environment**
   
   **On macOS/Linux:**
   ```bash
   source venv/bin/activate
   ```
   
   **On Windows:**
   ```bash
   venv\Scripts\activate
   ```

4. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

5. **Run database migrations**
   ```bash
   python manage.py migrate
   ```

6. **Start the development server**
   ```bash
   python manage.py runserver
   ```

## Important Notes
- Always activate the virtual environment before working on the project
- The `requirements.txt` file contains all necessary packages with specific versions
- If you add new packages, update the requirements file: `pip freeze > requirements.txt`

## Troubleshooting
- If you encounter permission errors, try using `python3` instead of `python`
- Make sure you're in the correct directory (`backend/`) when running commands
- If packages fail to install, try upgrading pip: `pip install --upgrade pip`
