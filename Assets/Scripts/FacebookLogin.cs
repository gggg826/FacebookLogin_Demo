using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.UI;
using System.Text;
using System.Web;
using IEnumerator = System.Collections.IEnumerator;

public class FacebookLogin : MonoBehaviour
{
    public Text text;
    bool GameCenterState = false;
    StringBuilder sb = new StringBuilder();
    private string iris_mc_type;
    private string user_token;
    private string user_id;

    [DllImport("__Internal")]
    private static extern void CallFromUnity_FacebookInit();


    [DllImport("__Internal")]
    private static extern void CallFromUnity_FacebookUserLogin();

    private void Awake()
    {
        //CallFromUnity_FacebookInit();
    }

 
    public void FacebookLoginClick()
    {
        CallFromUnity_FacebookUserLogin();
    }
    
    //logincallback
    public void LoginCallBack(string callBackMessage)
    {
        PrintLog($"callBackMessage        {callBackMessage}");
        string[] temp = callBackMessage.Split('|');
        iris_mc_type = temp[0];
        user_token = temp[1];
        user_id = temp[2];
        if (!string.IsNullOrEmpty(user_token))
        {
            StartCoroutine(LoginGame(user_token));
        }
    }

    public IEnumerator LoginGame(string access_token)
    {
        string temp = $"http://api.funrockgame001.com/api/extendaccount?sid={access_token}&passwd=wuditianyu&types=1&cv=1.0.1&udid={SystemInfo.deviceUniqueIdentifier}&mc=2001&mc_type={iris_mc_type}";

        PrintLog($"Login Url=={temp}");

        WWW nwww = new WWW(temp);
        
        yield return nwww;

        if (nwww.isDone && string.Empty != nwww.text)
        {
            string text = nwww.text;
            PrintLog($" nwww.text=={ nwww.text}");
        }
        else
        {
            PrintLog($" nwww.error=={ nwww.error}");
        }
    }


    private void PrintLog(string str)
    {
        Debug.Log(str);
        sb.Append("\n\n" + str);
        text.text = sb.ToString();
    }
    
    public void ClearLogClick()
    {
        if (sb != null)
        {
            sb.Clear();
            text.text = sb.ToString();
        }
    }
}
