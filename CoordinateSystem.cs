using Microsoft.Xna.Framework;

namespace Boat
{
    public static class CoordinateSystem
    {
        private static Vector2 _originOffset;

        public static void Initialize(Vector2 originOffset)
        {
            _originOffset = originOffset;
        }

        public static Vector2 GetPlayerPosition(Vector2 playerPosition)
        {
            Vector2 adjustedPosition = playerPosition - _originOffset;
            return new Vector2(adjustedPosition.X, -adjustedPosition.Y) / 50f;
        }
    }
}