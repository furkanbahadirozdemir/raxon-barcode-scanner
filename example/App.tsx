import { useCallback, useState } from 'react';
import { Button, FlatList, SafeAreaView, StyleSheet, Switch, Text, View } from 'react-native';

import { useBarcodeScanner, type BarcodeScanPayload } from 'raxon-barcode-scanner';

type ScanHistoryItem = BarcodeScanPayload & { id: string };

export default function App() {
  const [enabled, setEnabled] = useState(true);
  const [history, setHistory] = useState<ScanHistoryItem[]>([]);

  const onReadBarcode = useCallback((payload: BarcodeScanPayload) => {
    setHistory((current) => [
      {
        ...payload,
        id: `${Date.now()}-${payload.code}`,
      },
      ...current,
    ]);
  }, []);

  const scanner = useBarcodeScanner(enabled, onReadBarcode);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Raxon Barcode Scanner</Text>
        <Text style={styles.subtitle}>
          Zebra / DataWedge cihazlarda fiziksel barkod okuyucuyu test edin.
        </Text>
      </View>

      <View style={styles.card}>
        <View style={styles.row}>
          <Text style={styles.label}>Dinleyici aktif</Text>
          <Switch value={enabled} onValueChange={setEnabled} />
        </View>
        <Text style={styles.status}>
          Durum: {scanner.isListening ? 'Dinleniyor' : 'Kapalı'}
        </Text>
        <Button title="Geçmişi temizle" onPress={() => setHistory([])} />
      </View>

      <FlatList
        data={history}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.list}
        ListEmptyComponent={
          <Text style={styles.empty}>
            Henüz barkod okunmadı. Cihazın tetik tuşuyla okutmayı deneyin.
          </Text>
        }
        renderItem={({ item }) => (
          <View style={styles.scanItem}>
            <Text style={styles.scanCode}>{item.code}</Text>
            {item.symbology ? <Text style={styles.scanMeta}>{item.symbology}</Text> : null}
          </View>
        )}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f3f4f6',
  },
  header: {
    padding: 20,
    gap: 8,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: '#111827',
  },
  subtitle: {
    fontSize: 15,
    color: '#4b5563',
    lineHeight: 22,
  },
  card: {
    marginHorizontal: 20,
    marginBottom: 16,
    padding: 16,
    borderRadius: 12,
    backgroundColor: '#ffffff',
    gap: 12,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    color: '#111827',
  },
  status: {
    fontSize: 14,
    color: '#374151',
  },
  list: {
    paddingHorizontal: 20,
    paddingBottom: 24,
    gap: 12,
  },
  empty: {
    textAlign: 'center',
    color: '#6b7280',
    marginTop: 24,
    lineHeight: 22,
  },
  scanItem: {
    backgroundColor: '#ffffff',
    borderRadius: 12,
    padding: 16,
    gap: 4,
  },
  scanCode: {
    fontSize: 18,
    fontWeight: '600',
    color: '#111827',
  },
  scanMeta: {
    fontSize: 13,
    color: '#6b7280',
  },
});
