import { useState, useRef, useCallback, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Camera, RotateCcw, Check, X } from 'lucide-react';

interface WebcamCaptureProps {
  label: string;
  required?: boolean;
  onCapture: (imageBase64: string) => void;
  capturedImage?: string;
  onClear?: () => void;
}

export function WebcamCapture({ label, required = false, onCapture, capturedImage, onClear }: WebcamCaptureProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [streaming, setStreaming] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const streamRef = useRef<MediaStream | null>(null);

  const startCamera = useCallback(async () => {
    try {
      setError(null);
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: 'environment', width: { ideal: 1280 }, height: { ideal: 720 } },
      });
      streamRef.current = stream;
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        await videoRef.current.play();
        setStreaming(true);
      }
    } catch (err) {
      setError('No se pudo acceder a la cámara. Verifica los permisos.');
      console.error('Error accessing camera:', err);
    }
  }, []);

  const stopCamera = useCallback(() => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(track => track.stop());
      streamRef.current = null;
    }
    setStreaming(false);
  }, []);

  const takePhoto = useCallback(() => {
    if (!videoRef.current || !canvasRef.current) return;
    const video = videoRef.current;
    const canvas = canvasRef.current;
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    ctx.drawImage(video, 0, 0);
    const dataUrl = canvas.toDataURL('image/jpeg', 0.8);
    onCapture(dataUrl);
    stopCamera();
  }, [onCapture, stopCamera]);

  useEffect(() => {
    return () => stopCamera();
  }, [stopCamera]);

  if (capturedImage) {
    return (
      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <span className="text-sm font-medium">
            {label} {required && <span className="text-destructive">*</span>}
          </span>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => {
              onClear?.();
            }}
            className="gap-1 text-xs"
          >
            <RotateCcw className="w-3 h-3" />
            Retomar
          </Button>
        </div>
        <div className="rounded-lg overflow-hidden border border-border">
          <img src={capturedImage} alt={label} className="w-full h-40 object-cover" />
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-2">
      <span className="text-sm font-medium">
        {label} {required && <span className="text-destructive">*</span>}
      </span>
      {streaming ? (
        <div className="space-y-2">
          <div className="rounded-lg overflow-hidden border border-primary relative">
            <video ref={videoRef} className="w-full h-40 object-cover" autoPlay playsInline muted />
            <div className="absolute bottom-2 left-0 right-0 flex justify-center gap-2">
              <Button size="sm" onClick={takePhoto} className="gap-1">
                <Camera className="w-4 h-4" />
                Capturar
              </Button>
              <Button size="sm" variant="outline" onClick={stopCamera}>
                <X className="w-4 h-4" />
              </Button>
            </div>
          </div>
        </div>
      ) : (
        <Card
          className="h-40 flex flex-col items-center justify-center cursor-pointer border-dashed border-2 hover:bg-accent/50 transition-colors"
          onClick={startCamera}
        >
          {error ? (
            <p className="text-destructive text-sm text-center px-4">{error}</p>
          ) : (
            <>
              <Camera className="w-8 h-8 text-muted-foreground mb-2" />
              <span className="text-sm text-muted-foreground">Toca para abrir cámara</span>
            </>
          )}
        </Card>
      )}
      <canvas ref={canvasRef} className="hidden" />
    </div>
  );
}
