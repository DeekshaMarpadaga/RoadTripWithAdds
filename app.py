#appy.py
from flask import Flask, request, redirect, render_template, url_for, jsonify
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
        distance = request.form['distance']  
        duration = request.form['duration']  
        stop=request.form['stop']
        db.insert_trip(start, end, distance, duration,stop)
        
        # Redirect to another page, maybe to the list of trips
        return redirect('/see')
    else:
        return render_template('plan.html')

@app.route('/see')
def see_trips():
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
    trips = db.get_trips()  
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

@app.route('/complete/<int:trip_id>', methods=['POST'])
def complete(trip_id):
    date = request.form['completion_date']
    db.complete(trip_id,date)
    trips = db.get_trips()
    return redirect('/see')

@app.route('/delete_packing_item/<int:item_id>/<int:trip_id>')
def delete_packing_item(item_id, trip_id):
    db.delete_packing_item(item_id)
    return redirect(f'/packing_list/{trip_id}')
@app.route('/completed_trips')
def see_completed_trips():
    trips = db.get_completed_trips()
    return render_template('view_completed.html', trips=trips)
@app.route('/update_item_status/<int:item_id>', methods=['POST'])
def update_item_status(item_id):
    # Get the new checkbox state from the request
    data = request.get_json()
    is_checked = data.get('checked', False)  # 'checked' will be true or false

    # Find the item in the database
    
    if is_checked==True:
        # Update the checked state in the database (True for checked, False for unchecked)
        db.check(item_id)

    else:
        # Return a failure response if the item doesn't exist
        db.uncheck(item_id)


@app.route('/api/stats', methods=['GET'])
def get_stats():
    # Fetch the statistics
    total_distance = db.get_total_distance()
    total_time = db.get_total_time()
    total_trips = db.get_total_trips()
    
    stats = {
        "total_distance": total_distance,
        "total_time": total_time,
        "total_trips": total_trips
    }
    
    return jsonify(stats)

@app.route('/api/trip_data', methods=['GET'])
def get_trip_data():
    trip_data=db.month_miles()
    return jsonify(trip_data)
@app.route('/api/locations', methods=['GET'])
def get_locations_data():
    locations=db.locations()
    return jsonify(locations)


if __name__ == '__main__':
    app.run(debug=True)
