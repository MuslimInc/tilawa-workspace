import { devAdminLogin } from './environment.development.local';

export const environment = {
  production: false,
  firebase: {
    apiKey: "AIzaSyCbarh-SeVF7qEUXHvvnC1xZOUBY7GQOHo",
    authDomain: "quran-playera-app.firebaseapp.com",
    projectId: "quran-playera-app",
    storageBucket: "quran-playera-app.firebasestorage.app",
    messagingSenderId: "181575856185",
    appId: "1:181575856185:web:a70d1c264cf46898381de8",
    measurementId: "G-SB4J6TGRQL"
  },
  devAdminLogin,
};
