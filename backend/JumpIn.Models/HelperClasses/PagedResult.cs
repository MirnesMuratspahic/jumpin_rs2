namespace JumpIn.Models.HelperClasses
{
    public class PagedResult<T>
    {
        public List<T> ResultList { get; set; } = new List<T>();
        public int Count { get; set; }
    }
}
