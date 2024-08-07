//地形生成
using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

namespace Boat
{
    public static class ObstacleGenerator
    {
        public static List<Vector2> GenerateObstacles(int seed, int count, Vector2 playerPosition, Vector2 obstacleSize, Vector2 areaSize)
        {
            List<Vector2> positions = new List<Vector2>();
            Random random = new Random(seed);

            for (int i = 0; i < count; i++)
            {
                Vector2 position;
                bool overlapping;
                do
                {
                    overlapping = false;
                    position = new Vector2(
                        (float)(random.NextDouble() * areaSize.X),
                        (float)(random.NextDouble() * areaSize.Y)
                    );

                    // 检查是否与玩家或其他障碍物重叠
                    if (Vector2.Distance(position, playerPosition) < obstacleSize.Length())
                    {
                        overlapping = true;
                    }

                    foreach (var pos in positions)
                    {
                        if (Vector2.Distance(position, pos) < obstacleSize.Length() / 4)
                        {
                            overlapping = true;
                            break;
                        }
                    }

                } while (overlapping);

                positions.Add(position);
            }

            return positions;
        }

        private static int GetIntFromHash(byte[] hash, int startIndex)
        {
            return BitConverter.ToInt32(hash, startIndex) & int.MaxValue;
        }

        public static int GenerateCountFromHash(string hashInput, int maxCount)
        {
            using (SHA256 sha256 = SHA256.Create())
            {
                byte[] hash = sha256.ComputeHash(Encoding.UTF8.GetBytes(hashInput));
                return GetIntFromHash(hash, 0) % maxCount;
            }
        }
    }
}