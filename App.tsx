import { useEffect } from 'react';
import { Text, View } from 'react-native';
import { scheduleOnUI } from 'react-native-worklets';

function hello() {
  'worklet';
  console.log('hello from the UI runtime');
}

export default function App() {
  useEffect(() => {
    scheduleOnUI(hello);
  }, []);

  return (
    <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
      <Text>Bundle Mode cache repro</Text>
    </View>
  );
}
