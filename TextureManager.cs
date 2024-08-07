using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Boat
{
    public static class TextureManager
    {
        private static float _scale = 2f; // 初始缩放比例为 2f
        private static int _baseHeight = 720;

        public static void UpdateScale(int windowHeight)
        {
            _scale = windowHeight / (float)_baseHeight * 2f; // 保持初始比例为 2f
        }

        public static void DrawTexture(SpriteBatch spriteBatch, Texture2D texture, Vector2 position, Color color)
        {
            spriteBatch.Draw(texture, position, null, color, 0f, Vector2.Zero, _scale, SpriteEffects.None, 0f);
        }

        public static float Scale => _scale;
    }
}