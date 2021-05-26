using System;
using System.Data;
using Microsoft.SqlServer.Server;
using System.Data.SqlTypes;
using System.IO;
using System.Collections;

//namespace sqlClr
//{
public class ScalarFunctions
{
    /// <summary>
    /// Выводит строку без пробелов слева и справа от текста.
    /// </summary>
    [SqlFunction
    (
        Name = "fnTrim"
        , IsDeterministic = true
    )]
    public static string fnTrim(string trimStr)
    {
        return trimStr.Trim();
    }
        
}

/// <summary>
/// Аналог встроенной STRING_AGG для неповторяющихся элементов.
/// </summary>
[Serializable]
[SqlUserDefinedAggregate(Format.UserDefined, MaxByteSize = 8000)]
public class StringAggDistinct:IBinarySerialize
{
    ArrayList list;
    string separator;

    public void Init()
    {
        list = new ArrayList();
        separator = ", ";
    }

    public void Accumulate(SqlString value, SqlString delimeter)
    {
        separator = (delimeter.IsNull) ? "," : delimeter.Value;
        if (value.IsNull)
        {
            return;
        }
        if (!list.Contains(value.Value))
        {
            list.Add(value.Value);
        }
    }

    public void Merge(StringAggDistinct group)
    {
        list.AddRange(group.list);
    }

    public SqlString Terminate()
    {
        string[] strings = new string[list.Count];

        for (int i = 0; i < list.Count; i++)
        {
            strings[i] = list[i].ToString();
        }

        return new SqlString(string.Join(separator, strings));
    }

    public void Read(BinaryReader r)
    {
        int itemCount = r.ReadInt32();
        list = new ArrayList(itemCount);

        for (int i = 0; i < itemCount; i++)
        {
            this.list.Add(r.ReadString());
        }
    }

    public void Write(BinaryWriter w)
    {
        w.Write(list.Count);
        for (int i = 0; i < list.Count; i++)
        {
            if (i < list.Count - 1)
            {
                w.Write(list[i].ToString() + separator);
            }
            else
            {
                w.Write(list[i].ToString());
            }
        }
    }
}
//}
