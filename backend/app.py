from flask import Flask, request, jsonify
from flask_bcrypt import Bcrypt
from flask_mysqldb import MySQL
from flask_cors import CORS
import os
from flask import session, redirect, url_for
from flask_session import Session  
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)
CORS(app, supports_credentials=True)
bcrypt = Bcrypt(app)

app.config['SECRET_KEY'] = os.urandom(24)  
app.config['SESSION_TYPE'] = 'filesystem' 
Session(app)

# Configuration for MySQL
app.config['MYSQL_HOST'] = os.getenv('MYSQL_HOST')
app.config['MYSQL_USER'] = os.getenv('MYSQL_USER')
app.config['MYSQL_PASSWORD'] = os.getenv('MYSQL_PASSWORD')
app.config['MYSQL_DB'] = os.getenv('MYSQL_DB')

mysql = MySQL(app)

# Sign-Up route
@app.route('/signup', methods=['POST'])
def signup():
    data = request.get_json()
    username = data['username']
    email = data['email']
    password = data['password']

    cur = mysql.connection.cursor()
    # Check if user already exists
    cur.execute("SELECT * FROM users WHERE email = %s", (email,))
    user = cur.fetchone()
    if user:
        return jsonify({"error": "User already exists"}), 400
    
    # Hash the password
    password_hash = bcrypt.generate_password_hash(password).decode('utf-8')

    # Insert new user into the database
    cur.execute("INSERT INTO users (username, email, password_hash) VALUES (%s, %s, %s)",
                (username, email, password_hash))
    mysql.connection.commit()
    cur.close()

    return jsonify({"message": "User registered successfully!"}), 201

@app.route('/signin', methods=['POST'])
def signin():
    data = request.get_json()
    email = data['email']
    password = data['password']

    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM users WHERE email = %s", (email,))
    user = cur.fetchone()
    cur.close()

    if not user:
        return jsonify({"error": "User does not exist"}), 404

    if bcrypt.check_password_hash(user[3], password):
        session['user_id'] = user[0]  
        session['username'] = user[1]  
        return jsonify({"message": "Sign-in successful!"}), 200
    else:
        return jsonify({"error": "Invalid credentials"}), 401

    
@app.route('/logout', methods=['POST'])
def logout():
    session.clear()
    return jsonify({"message": "Logged out successfully!"}), 200

@app.route('/add_bookmark', methods=['POST'])
def add_bookmark():
    if 'user_id' not in session:
        print("Session does not contain user_id")
        return jsonify({"error": "User not signed in"}), 401
    else:
        print(f"User ID in session: {session['user_id']}")
    
    data = request.get_json()
    user_id = session['user_id']

    required_fields = ['title', 'description', 'url', 'imageUrl']
    if not all(field in data for field in required_fields):
        return jsonify({"error": "Missing required fields"}), 400

    article_title = data['title']
    article_description = data['description']
    article_url = data['url']
    article_image_url = data['imageUrl']

    try:
        cur = mysql.connection.cursor()
        cur.execute("INSERT INTO bookmarks (user_id, article_title, article_description, article_url, article_image_url) "
                    "VALUES (%s, %s, %s, %s, %s)", 
                    (user_id, article_title, article_description, article_url, article_image_url))
        mysql.connection.commit()
        cur.close()
        return jsonify({"message": "Bookmark added successfully!"}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/bookmarks', methods=['GET'])
def get_bookmarks():
    if 'user_id' not in session:
        return jsonify({"error": "User not signed in"}), 401

    user_id = session['user_id']
    
    cur = mysql.connection.cursor()
    cur.execute("SELECT article_title, article_description, article_url, article_image_url FROM bookmarks WHERE user_id = %s", 
                (user_id,))
    bookmarks = cur.fetchall()
    cur.close()

    bookmark_list = [
        {
            "title": bookmark[0],
            "description": bookmark[1],
            "url": bookmark[2],
            "imageUrl": bookmark[3]
        } for bookmark in bookmarks
    ]

    return jsonify(bookmark_list), 200

@app.route('/remove_bookmark', methods=['POST'])
def remove_bookmark():
    if 'user_id' not in session:
        return jsonify({"error": "User not signed in"}), 401

    data = request.get_json()
    article_url = data.get('url') 

    if not article_url:
        return jsonify({"error": "Article URL is required"}), 400

    user_id = session['user_id']

    try:
        cur = mysql.connection.cursor()
        cur.execute("DELETE FROM bookmarks WHERE user_id = %s AND article_url = %s", (user_id, article_url))
        mysql.connection.commit()
        cur.close()
        return jsonify({"message": "Bookmark removed successfully!"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
