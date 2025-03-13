import { lazy, Suspense } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { ErrorBoundary } from 'react-error-boundary';
import { Box, Spinner, Text, Center } from '@chakra-ui/react';

// 頁面組件懶加載
const Layout = lazy(() => import('./components/layout/Layout'));
const Login = lazy(() => import('./pages/Auth/Login'));
const Register = lazy(() => import('./pages/Auth/Register'));
const Dashboard = lazy(() => import('./pages/Home/Dashboard'));
const AudioUpload = lazy(() => import('./pages/AudioUpload/AudioUpload'));
const TranscriptView = lazy(() => import('./pages/TranscriptView/TranscriptView'));
const ContentGeneration = lazy(() => import('./pages/ContentGeneration/ContentGeneration'));
const KnowledgeBase = lazy(() => import('./pages/KnowledgeBase/KnowledgeBase'));
const Settings = lazy(() => import('./pages/Settings/Settings'));
const NotFound = lazy(() => import('./pages/NotFound'));

// 保護路由組件
import ProtectedRoute from './components/common/ProtectedRoute';

// 讀取中組件
const LoadingFallback = () => (
  <Center h="100vh">
    <Box textAlign="center">
      <Spinner size="xl" color="brand.500" mb={4} />
      <Text>載入中...</Text>
    </Box>
  </Center>
);

// 錯誤邊界組件
const ErrorFallback = ({ error }: { error: Error }) => (
  <Center h="100vh">
    <Box textAlign="center" p={5}>
      <Text fontSize="xl" fontWeight="bold" mb={2}>出現錯誤</Text>
      <Text mb={4}>很抱歉，應用程式發生問題。</Text>
      <Text color="red.500">{error.message}</Text>
      <Text mt={4} as="button" color="brand.500" onClick={() => window.location.reload()}>
        重新載入頁面
      </Text>
    </Box>
  </Center>
);

function App() {
  return (
    <ErrorBoundary FallbackComponent={ErrorFallback}>
      <Suspense fallback={<LoadingFallback />}>
        <Routes>
          {/* 公開路由 */}
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          
          {/* 受保護路由 */}
          <Route path="/" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
            <Route index element={<Navigate to="/dashboard" replace />} />
            <Route path="dashboard" element={<Dashboard />} />
            <Route path="audio-upload" element={<AudioUpload />} />
            <Route path="transcripts" element={<TranscriptView />} />
            <Route path="transcripts/:id" element={<TranscriptView />} />
            <Route path="content-generation" element={<ContentGeneration />} />
            <Route path="content-generation/:transcriptId" element={<ContentGeneration />} />
            <Route path="knowledge-base" element={<KnowledgeBase />} />
            <Route path="settings" element={<Settings />} />
          </Route>
          
          {/* 404 頁面 */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </Suspense>
    </ErrorBoundary>
  );
}

export default App;