# Frontend
Flutter

Dio: A powerful HTTP client for Dart, used for making API requests.

Cached Network Image: A package that caches images for better performance.

# Backend
Flask

MySQL

Flask-Bcrypt: For hashing passwords securely.

Flask-CORS: To handle Cross-Origin Resource Sharing, allowing the frontend to communicate with the backend.

Flask-Session: For managing user sessions.

# Project Structure
## Flutter
Main Application (main.dart): The entry point of the Flutter application, which initializes the app and sets up the routing.

Search Functionality (news_search_delegate.dart): This component provides a search interface for users to find news articles. It fetches data from the backend using the NewsService class and displays results dynamically.

Article Card Display: Each article is presented using a card layout, which includes the title, description, and image. Tapping on an article opens its link in a browser.

Search Bar: Located at the top of the app for searching articles.

List View: Displays articles in a scrollable list, dynamically populated based on search results or user preferences.

Bookmarks: Allows users to save articles for later viewing.

## Flask
Sign-Up Route (/signup): Allows new users to register by providing a username, email, and password. The password is hashed for security before storing it in the database.

Sign-In Route (/signin): Authenticates users by checking the provided credentials. Upon successful login, a session is created to track the user.

Logout Route (/logout): Clears the user session, effectively logging the user out.

Add Bookmark (/add_bookmark): Allows logged-in users to save articles by sending the article details.

Get Bookmarks (/bookmarks): Retrieves all bookmarks for the logged-in user.

Remove Bookmark (/remove_bookmark): Deletes a bookmark based on the provided URL.

## Database Structure
Users Table: Stores user information, including username, email, and hashed passwords.

Bookmarks Table: Stores bookmarks associated with each user, including article details.


