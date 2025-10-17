import {
  StyleSheet,
  Text,
  View,
  TextInput,
  Button,
  FlatList,
} from 'react-native';
import { WebView } from 'react-native-webview';
import React from 'react';
import { SafeAreaView, SafeAreaProvider } from 'react-native-safe-area-context';
import { DrawerScreenProps } from '@react-navigation/drawer';
import { Book } from '../../entities/book';

/*
todo : make a script that loads pages from ?page=1 to 
?page=unknown
with a delta of 1 to X random seconds (between 1 and 10)
(make it load until there is no more items)
*/

/*
extract all images from page 
if length > 2 then OK, else chapter unavailable
Array.from(document.getElementById('chapter-above-ads').nextElementSibling.querySelectorAll('img')).filter(x => x.src.startsWith('https://gg.asuracomic.net/storage/media/')).map(x => x.src)
*/

const SettingsScreen : React.FC<any> = ({ navigation }) => {
  const [data, setData] = React.useState<Book[]>([]);
  const [host, onChangeHost] = React.useState('host');
  const [url, changeUrl] = React.useState('');
  const [startProcess, changeRun] = React.useState(false);
  const sethost = () => {
    changeUrl(host + '/series');
  };

  const start = () => {
    changeRun(true);
  }

  const extractLinks = () => {
    const script = `
      (function() {
        const data = Array.from(document.querySelectorAll('a')).filter(x => x.href.startsWith('${url}') && x.innerHTML.startsWith('<div')).map(a => ({link: a.href, image: a.querySelector('img').src, status: a.querySelectorAll('span')[0].innerText, type: a.querySelectorAll('span')[1].innerText,  title: a.querySelectorAll('span')[2].innerText,  latest: a.querySelectorAll('span')[3].innerText}));
        window.ReactNativeWebView.postMessage(JSON.stringify(data));
      })();
    `;
    return script;
  };

  const handleMessage = (event: { nativeEvent: { data: string; }; }) => {
    const extractedData = JSON.parse(event.nativeEvent.data);
    setData(extractedData);
  };

  return (
    <SafeAreaProvider>
      <SafeAreaView style={styles.container}>
        <Button title="Set Host" onPress={sethost} />
        <Button title="Run" onPress={start} />
        <TextInput
          style={styles.input}
          onChangeText={onChangeHost}
          value={host}
        />
        {startProcess && 
        <>
        <View style={styles.webViewContainer}>
          <WebView
            style={styles.webView}
            source={{ uri: url }}
            injectedJavaScript={extractLinks()}
            onMessage={handleMessage}
          />
        </View>
        </>
        }
        <FlatList
          data={data}
          keyExtractor={(item, index) => index.toString()}
          renderItem={({ item }) => (
            <View style={styles.linkItem}>
              <Text>{item.type}</Text>
              <Text>{item.title}</Text>
              <Text>{item.link}</Text>
              <Text>{item.image}</Text>
              <Text>{item.status}</Text>
              <Text>{item.latest}</Text>
            </View>
          )}
        />
      </SafeAreaView>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'grey'
  },
  webViewContainer: {
    width: 50,
    height: 50,
    overflow: 'hidden', // Ensure the WebView does not overflow the container
  },
  webView: {
    flex: 1, // Make the WebView take up the full size of the container
  },
  input: {
    height: 40,
    margin: 12,
    borderWidth: 1,
    padding: 10,
  },
  linkItem: {
    padding: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#ccc',
  },
});

export default SettingsScreen;
