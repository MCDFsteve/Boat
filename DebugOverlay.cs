using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Boat
{
    public class DebugOverlay
    {
        private SpriteFont _font;

        public DebugOverlay(SpriteFont font)
        {
            _font = font;
        }

        public void Draw(SpriteBatch spriteBatch, int tileCount, Vector2 playerPosition)
        {
            string tileText = $"Background Tiles: {tileCount}";
            string coordText = $"Player Position: {playerPosition.X:F1}, {playerPosition.Y:F1}";
            spriteBatch.DrawString(_font, tileText, new Vector2(10, 10), Color.White);
            spriteBatch.DrawString(_font, coordText, new Vector2(10, 30), Color.White);
        }
    }
}