using Microsoft.Xna.Framework;
using System;

namespace Boat
{
    public static class ColorHelper
    {
        public static Color FromHex(string hex)
        {
            // 去掉 # 符号
            hex = hex.Replace("#", string.Empty);

            // 解析 R、G、B 分量
            byte r = Convert.ToByte(hex.Substring(0, 2), 16);
            byte g = Convert.ToByte(hex.Substring(2, 2), 16);
            byte b = Convert.ToByte(hex.Substring(4, 2), 16);

            return new Color(r, g, b);
        }
    }
}