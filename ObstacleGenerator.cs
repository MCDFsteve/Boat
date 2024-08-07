using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text;

namespace Boat
{
    public static class ObstacleGenerator
    {
        public static List<Vector2> GenerateObstaclesForClosedLoop(string hashInput, int obstacleCount, float radius, float irregularity)
        {
            List<Vector2> positions = new List<Vector2>();

            Random random = new Random(hashInput.GetHashCode());
            float angleStep = 2 * MathF.PI / obstacleCount;

            Vector2? previousPosition = null;

            for (int i = 0; i < obstacleCount; i++)
            {
                float angle = i * angleStep;
                float noise = (float)(random.NextDouble() * 2 - 1) * irregularity;

                float r = radius + noise * radius;
                float x = r * MathF.Cos(angle);
                float y = r * MathF.Sin(angle);

                Vector2 position = new Vector2(x, y);

                // Check for gaps and fill them
                if (previousPosition.HasValue)
                {
                    FillGaps(previousPosition.Value, position, positions, 65);
                }

                positions.Add(position);
                previousPosition = position;
            }

            // Ensure the shape is closed by connecting the last point to the first
            FillGaps(positions[positions.Count - 1], positions[0], positions, 65);

            return positions;
        }

        private static void FillGaps(Vector2 start, Vector2 end, List<Vector2> positions, float distance)
        {
            float gap = Vector2.Distance(start, end);
            while (gap > distance)
            {
                Vector2 direction = Vector2.Normalize(end - start);
                start += direction * distance;
                positions.Add(start);
                gap = Vector2.Distance(start, end);
            }
        }

        public static int GenerateCountFromHash(string hashInput, int maxCount)
        {
            using (SHA256 sha256 = SHA256.Create())
            {
                byte[] hash = sha256.ComputeHash(Encoding.UTF8.GetBytes(hashInput));
                return GetIntFromHash(hash, 0) % maxCount + 1;
            }
        }

        public static List<Vector2> GenerateObstacles(int seed, Vector2 playerPosition, Vector2 obstacleSize, Vector2 areaSize)
        {
            string hashInput = seed.ToString(); // 将种子转换为字符串，作为哈希输入
            int obstacleCount = GenerateCountFromHash(hashInput, 100); // 随机生成障碍物数量
            float radius = areaSize.X / 3; // 调整这个值以设置洞穴的平均半径
            float irregularity = 0.3f; // 调整这个值以增加或减少不规则性

            return GenerateObstaclesForClosedLoop(hashInput, obstacleCount, radius, irregularity);
        }

        private static float GetFloatFromHash(byte[] hash, int index)
        {
            // 确保索引不会超出哈希数组的长度
            index = index % (hash.Length - sizeof(uint));
            return BitConverter.ToUInt32(hash, index) / (float)uint.MaxValue;
        }

        private static int GetIntFromHash(byte[] hash, int startIndex)
        {
            // 确保索引不会超出哈希数组的长度
            startIndex = startIndex % (hash.Length - sizeof(int));
            return BitConverter.ToInt32(hash, startIndex) & int.MaxValue;
        }
    }
}