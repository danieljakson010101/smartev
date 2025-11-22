const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const chargingStations = [
  {
    name: "ChargEV - Petronas PLUS Highway",
    location: new admin.firestore.GeoPoint(3.1390, 101.6869),
    address: "PLUS Highway Rest Area, KM 245",
    availableChargers: 3,
    totalChargers: 4,
    chargerType: "DC Fast",
    pricePerKwh: 1.20,
    operator: "ChargEV",
    amenities: ["Restroom", "Cafe", "Convenience Store"],
    distance: 24.5,
    estimatedTime: 18,
    reachable: true,
    energyRequired: 15
  },
  {
    name: "JomCharge - Shell R&R Tapah",
    location: new admin.firestore.GeoPoint(4.1904, 101.2672),
    address: "Shell Tapah R&R",
    availableChargers: 2,
    totalChargers: 3,
    chargerType: "DC Fast",
    pricePerKwh: 1.15,
    operator: "JomCharge",
    amenities: ["Restroom", "Food Court"],
    distance: 45.2,
    estimatedTime: 32,
    reachable: true,
    energyRequired: 28
  },
  {
    name: "TNB EV - Ipoh Gateway",
    location: new admin.firestore.GeoPoint(4.5975, 101.0901),
    address: "Ipoh Gateway Shopping Mall",
    availableChargers: 1,
    totalChargers: 2,
    chargerType: "AC Charge",
    pricePerKwh: 0.80,
    operator: "TNB",
    amenities: ["Shopping Mall", "Food Court", "Cinema"],
    distance: 68.7,
    estimatedTime: 48,
    reachable: false,
    energyRequired: 42
  },
  {
    name: "Gentari - KLIA Highway",
    location: new admin.firestore.GeoPoint(2.7456, 101.7072),
    address: "KLIA Highway Service Area",
    availableChargers: 0,
    totalChargers: 4,
    chargerType: "DC Fast",
    pricePerKwh: 1.25,
    operator: "Gentari",
    amenities: ["Restroom", "Cafe"],
    distance: 89.3,
    estimatedTime: 62,
    reachable: false,
    energyRequired: 55
  }
];

async function seedData() {
  try {
    console.log('Starting to seed charging stations...');
    
    for (const station of chargingStations) {
      const docRef = await db.collection('charging_stations').add(station);
      console.log(`Added station: ${station.name} with ID: ${docRef.id}`);
    }
    
    console.log('Seeding completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding data:', error);
    process.exit(1);
  }
}

seedData();