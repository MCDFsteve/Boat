using Microsoft.Xna.Framework;
using System;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Text;

namespace Boat
{
    public static class ObstacleGenerator
    {
        public static List<Vector2> GenerateObstaclesForClosedLoop(int seed, int obstacleCount, float radius, float irregularity)
        {
            List<Vector2> positions = new List<Vector2>();

            Console.WriteLine($"Seed: {seed}");
            Random random = new Random(seed);

            // Step 1: 计算关键点
            List<Vector2> keyPoints = new List<Vector2>();
            float minDistance = radius / (obstacleCount * 0.5f);  // 设置最小距离约束
            for (int i = 0; i < obstacleCount; i++)
            {
                float angle = i * (2 * MathF.PI / obstacleCount);
                float noise = (float)(random.NextDouble() * 2 - 1) * irregularity;

                float r = radius + noise * radius;
                float x = r * MathF.Cos(angle);
                float y = r * MathF.Sin(angle);

                if (keyPoints.Count > 0)
                {
                    Vector2 lastPoint = keyPoints[keyPoints.Count - 1];
                    if (Math.Abs(x - lastPoint.X) < minDistance)
                    {
                        x = lastPoint.X;  // 如果x距离太短，使用相同的x值
                    }
                    if (Math.Abs(y - lastPoint.Y) < minDistance)
                    {
                        y = lastPoint.Y;  // 如果y距离太短，使用相同的y值
                    }
                }

                // 对齐到整数格子
                x = MathF.Round(x);
                y = MathF.Round(y);

                keyPoints.Add(new Vector2(x, y));
            }

            // Step 2: 连接关键点，形成横竖交错的路径
            float maxAllowedDistance = radius / (obstacleCount * 0.5f); // 调整阈值
            for (int i = 0; i < keyPoints.Count; i++)
            {
                Vector2 startPoint = keyPoints[i];
                Vector2 endPoint = keyPoints[(i + 1) % keyPoints.Count];  // 确保最后一个点与第一个点相连

                // 水平移动
                if (startPoint.X != endPoint.X)
                {
                    float xDistance = Math.Abs(startPoint.X - endPoint.X);
                    int xSegments = (int)(xDistance / maxAllowedDistance);
                    for (int s = 1; s <= xSegments; s++)
                    {
                        float x = startPoint.X + s * (endPoint.X - startPoint.X) / (xSegments + 1);
                        x = MathF.Round(x);  // 对齐到整数格子
                        positions.Add(new Vector2(x, startPoint.Y));
                    }
                }

                // 检测转角并添加转角填充物
                if (startPoint.X != endPoint.X && startPoint.Y != endPoint.Y)
                {
                    // 添加转角处的填充物
                    positions.Add(new Vector2(endPoint.X, startPoint.Y));
                }

                // 垂直移动
                if (startPoint.Y != endPoint.Y)
                {
                    float yDistance = Math.Abs(startPoint.Y - endPoint.Y);
                    int ySegments = (int)(yDistance / maxAllowedDistance);
                    for (int s = 1; s <= ySegments; s++)
                    {
                        float y = startPoint.Y + s * (endPoint.Y - startPoint.Y) / (ySegments + 1);
                        y = MathF.Round(y);  // 对齐到整数格子
                        positions.Add(new Vector2(endPoint.X, y));
                    }
                }

                // 添加终点
                positions.Add(endPoint);
            }

            return positions;
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
            int obstacleCount = GenerateCountFromHash(seed.ToString(), 100); // 仍然可以根据种子生成障碍物数量
            float radius = areaSize.X / 3; // 调整这个值以设置洞穴的平均半径
            float irregularity = 0.3f; // 调整这个值以增加或减少不规则性

            return GenerateObstaclesForClosedLoop(seed, obstacleCount, radius, irregularity);
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