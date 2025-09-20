# SAHAYAK Setup Instructions

## Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Activate virtual environment:**
   ```bash
   source venv/bin/activate  # On Mac/Linux
   # OR
   .\venv\Scripts\Activate.ps1  # On Windows
   ```

3. **Install additional dependencies:**
   ```bash
   pip install djangorestframework django-cors-headers
   ```

4. **Run database migrations:**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

5. **Create a superuser (optional):**
   ```bash
   python manage.py createsuperuser
   ```

6. **Start the Django server:**
   ```bash
   python manage.py runserver
   ```
   The backend will be available at `http://127.0.0.1:8000`

## Frontend Setup

1. **Navigate to frontend directory:**
   ```bash
   cd frontend
   ```

2. **Get Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the Flutter app:**
   ```bash
   flutter run -d chrome  # For web
   # OR
   flutter run  # For mobile/desktop
   ```

## Testing the Integration

1. **Test the backend API:**
   ```bash
   cd backend
   python test_api.py
   ```

2. **Test the frontend:**
   - Open the Flutter app
   - Try registering a new user
   - Try logging in with existing credentials
   - Check if the home screen loads after authentication

## API Endpoints

- **POST** `/api/auth/register/` - User registration
- **POST** `/api/auth/login/` - User login
- **POST** `/api/auth/logout/` - User logout
- **GET** `/api/children/` - Get children (authenticated)
- **POST** `/api/children/` - Create child (authenticated)
- **GET** `/api/sessions/` - Get sessions (authenticated)
- **POST** `/api/sessions/` - Create session (authenticated)

## Troubleshooting

1. **CORS Issues:** Make sure the backend is running and CORS is configured
2. **Network Issues:** Check if the backend URL in `api_service.dart` is correct
3. **Authentication Issues:** Verify that tokens are being stored properly
4. **Database Issues:** Run migrations if you get database errors

## Next Steps

1. Implement the three core games (Star Tracer, Monster Munch, Echo Explorers)
2. Add child profile management
3. Integrate the ML model for analysis
4. Add progress tracking and reports
