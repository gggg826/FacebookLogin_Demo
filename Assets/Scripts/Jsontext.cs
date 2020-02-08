using UnityEngine;
using System.Collections;
using Pathfinding.Serialization;
using System.Collections.Generic;
using Pathfinding.Serialization.JsonFx;
using System;

public class Jsontext  {

	public static System.Text.StringBuilder  WriteData(Dictionary<string,object> data)
    {
        System.Text.StringBuilder stringbuilder = new System.Text.StringBuilder();
        JsonWriter jsdata = new JsonWriter(stringbuilder);
        jsdata.Write(data);
        return stringbuilder;

    }
    public static System.Text.StringBuilder WriteData<T>(T data)
    {
        System.Text.StringBuilder stringbuilder = new System.Text.StringBuilder();
        JsonWriter jsdata = new JsonWriter(stringbuilder);
        jsdata.Write(data);
        return stringbuilder;

    }
    public static object ReadeData(string text)
    {
        if (text == "" || text == "\n" || text == "\r\n" || text == "\r") return null;

        JsonReader reader = new JsonReader(text);
        if (reader != null)
        {
            try
            {
                object obj = reader.Deserialize();
                return obj;
            }
            catch (Exception e)
            {
                Debug.LogError("Parse Json Error:MSG:" + e.Message);
                return null;
            }

        }
        return null;
    }  
}
