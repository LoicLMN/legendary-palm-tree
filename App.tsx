import { NavigationContainer, DarkTheme } from '@react-navigation/native';
import { createDrawerNavigator } from '@react-navigation/drawer';
import HomeScreen from './presentation/screens/home';
import SettingsScreen from './presentation/screens/settings';
import {ServiceProvider} from './presentation/context/ServiceContext';

const Drawer = createDrawerNavigator();

export default function App() {
  return (
    <ServiceProvider>
      <NavigationContainer theme={DarkTheme}>
        <Drawer.Navigator initialRouteName="Home">
          <Drawer.Screen name="Home" component={HomeScreen} />
          <Drawer.Screen name="Settings" component={SettingsScreen} />
        </Drawer.Navigator>
      </NavigationContainer>
    </ServiceProvider>
  );
}
