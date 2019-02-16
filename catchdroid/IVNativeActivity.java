package net.vucica.catchdroid;
import android.app.NativeActivity;
import android.content.res.AssetManager;

public class IVNativeActivity extends NativeActivity
{
  static
  {
    /*
    AssetManager am = applicationContext.getAssets(); 
    in = am.open(OPENSSL_SO_LIB_NAME); // source instream

    File privateStorageDir = applicationContext.getFilesDir();
    String libPath = privateStorageDir.getAbsolutePath();
    */
    System.loadLibrary("log");
    System.loadLibrary("objc");
    System.loadLibrary("gnustep-base");
    System.loadLibrary("CatchDroid");
  }

  public static native void initAssetManager(AssetManager assetManager);
  public IVNativeActivity()
  {
    super();
  }
  public void onCreate(android.os.Bundle savedInstanceState)
  {
    super.onCreate(savedInstanceState);
    android.content.Context context = this;
    initAssetManager(context.getAssets());
  } 
}
