using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System.Collections.Generic;

namespace Boat
{
    public class DynamicBackground
    {
        private Texture2D _texture;
        private Viewport _viewport;
        private HashSet<Point> _visibleTiles;
        private int _textureWidth;
        private int _textureHeight;
        private int _viewWidth;
        private int _viewHeight;

        public DynamicBackground(Texture2D texture, Viewport viewport)
        {
            _texture = texture;
            _viewport = viewport;
            _textureWidth = (int)(_texture.Width * TextureManager.Scale);
            _textureHeight = (int)(_texture.Height * TextureManager.Scale);
            _viewWidth = viewport.Width + _textureWidth * 2;
            _viewHeight = viewport.Height + _textureHeight * 2;
            _visibleTiles = new HashSet<Point>();
        }

        public void Update(Viewport viewport, Vector2 playerPosition)
        {
            _viewport = viewport;
            _textureWidth = (int)(_texture.Width * TextureManager.Scale);
            _textureHeight = (int)(_texture.Height * TextureManager.Scale);
            _viewWidth = viewport.Width + _textureWidth * 2;
            _viewHeight = viewport.Height + _textureHeight * 2;
            UpdateVisibleTiles(playerPosition);
        }

        private void UpdateVisibleTiles(Vector2 playerPosition)
        {
            int playerX = (int)playerPosition.X;
            int playerY = (int)playerPosition.Y;

            int startX = (playerX - _viewWidth / 2) / _textureWidth;
            int startY = (playerY - _viewHeight / 2) / _textureHeight;
            int endX = (playerX + _viewWidth / 2) / _textureWidth;
            int endY = (playerY + _viewHeight / 2) / _textureHeight;

            _visibleTiles.Clear();
            for (int x = startX; x <= endX; x++)
            {
                for (int y = startY; y <= endY; y++)
                {
                    _visibleTiles.Add(new Point(x, y));
                }
            }
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            foreach (var tile in _visibleTiles)
            {
                Vector2 position = new Vector2(tile.X * _textureWidth, tile.Y * _textureHeight);
                TextureManager.DrawTexture(spriteBatch, _texture, position, Color.White);
            }
        }

        public int TileCount => _visibleTiles.Count;
    }
}