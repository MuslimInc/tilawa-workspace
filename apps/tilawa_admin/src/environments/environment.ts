export const environment = {
  production: true,
  /** Stable production scope — wallet/paid ops UI hidden until Phase 4. */
  quranSessionsWalletEnabled: false,
  firebase: {
    apiKey: "AIzaSyCbarh-SeVF7qEUXHvvnC1xZOUBY7GQOHo",
    authDomain: "quran-playera-app.firebaseapp.com",
    projectId: "quran-playera-app",
    storageBucket: "quran-playera-app.firebasestorage.app",
    messagingSenderId: "181575856185",
    appId: "1:181575856185:web:a70d1c264cf46898381de8",
    measurementId: "G-SB4J6TGRQL"
  },
  devAdminLogin: undefined as { email: string; password: string } | undefined,
};
