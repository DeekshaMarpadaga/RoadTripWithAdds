#__init__.py
from flask import Flask, request, redirect, render_template, url_for
import db  # Ensure this imports your db.py functionality for database interaction

app = Flask(__name__, static_url_path='/public', static_folder='public')

@app.route('/')
def index():
    return render_template('index.html', css_style="/public/css/styles.css")

@app.route('/plan', methods=['GET', 'POST'])
def plan_trip():
    if request.method == 'POST':
        # Extract form data
        start = request.form['start']
        end = request.form['end']
        distance = request.form['distance']  # Assuming you add a way to input this in the form
        duration = request.form['duration']  # Assuming you add a way to input this in the form
        stop=request.form['stop']
        # Assuming db.py has a function called insert_trip that inserts the data into the database
        db.insert_trip(start, end, distance, duration,stop)
        
        # Redirect to another page, maybe to the list of trips
        return redirect('/see')
    else:
        return render_template('plan.html')

@app.route('/see')
def see_trips():
    # Assuming db.py has a function called get_trips that fetches trips from the database
    trips = db.get_trips()
    return render_template('view_database.html', trips=trips)

@app.route('/view/<int:trip_id>')
def view_trip(trip_id):
    # Fetch trip details from the database based on trip_id
    trip = db.get_trip_by_id(trip_id)

    
    return render_template('view.html', trip=trip)
@app.route('/delete/<int:trip_id>')
def delete_trips(trip_id):

    trips = db.delete_trip(trip_id)
    trips = db.get_trips()
    return render_template('view_database.html', trips=trips)



@app.route('/about')
def about():
    return render_template('about.html')

@app.route('/contact')
def contact():
    return render_template('contact.html')

@app.route('/login')
def login():
    return render_template('login.html')

@app.route('/signup')
def signup():
    return render_template('signup.html')

@app.route('/stat')
def see_stats():
    trips = db.get_trips()  # Assuming this fetches all trips data
    total_distance = db.get_total_distance()
    total_time = db.get_total_time()
    total_trips = db.get_total_trips()
    flags = db.get_flags()
    return render_template('stat.html', trips=trips, total_distance=total_distance, total_time=total_time, total_trips=total_trips, flags=flags)

@app.route('/packing_list/<int:trip_id>', methods=['GET', 'POST'])
def packing_list(trip_id):
    if request.method == 'POST':
        item = request.form['item']
        db.add_packing_item(trip_id, item)
        return redirect(f'/packing_list/{trip_id}')
    
    items = db.get_packing_list(trip_id)
    trip = db.get_trip_by_id(trip_id)
    return render_template('packing_list.html', trip=trip, items=items)

@app.route('/delete_packing_item/<int:item_id>/<int:trip_id>')
def delete_packing_item(item_id, trip_id):
    db.delete_packing_item(item_id)
    return redirect(f'/packing_list/{trip_id}')
if __name__ == '__main__':
    app.run(debug=True)