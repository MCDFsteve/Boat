//坐标系统
using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text;
namespace Boat
{
    public static class CoordinateSystem
    {
        private static readonly Vector2 _originOffset = new Vector2(164, 164);
        public static Vector2 GetPlayerPosition(Vector2 playerPosition)
        {
            Vector2 adjustedPosition = playerPosition - _originOffset;
            return new Vector2(adjustedPosition.X, -adjustedPosition.Y) / 50f;
        }
    }
}